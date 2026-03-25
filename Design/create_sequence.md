```mermaid
sequenceDiagram
    actor Client as Client (HTTP)
    participant Security as Spring Security<br/>(JWT Filter)
    participant Controller as LedgersController<br/>POST /ledger
    participant Service as LedgerCommandService
    participant TxManager as Spring Transaction<br/>Manager
    participant LedgerMapper as LedgerMapper
    participant ItemsMapper as LedgerItemsMapper
    participant LedgerRepo as LedgerRepository<br/>(jOOQ)
    participant ItemsRepo as LedgerItemsRepository<br/>(jOOQ)
    participant DB as PostgreSQL<br/>(Command DB)

    %% yellow highlight
    rect rgba(255,255,0,0.15)
    note over Client,Controller: Security Logging
        Client->>Security: POST /ledger<br/>Authorization: Bearer <JWT>
        Security->>Security: Validate JWT token
        alt JWT invalid
            Security-->>Client: 401 Unauthorized
        end

        Security->>Controller: forward request + Jwt principal

        Controller->>Controller: @Validated — validate LedgersEntryDTO<br/>(BindingResult)
        alt Validation errors
            Controller-->>Client: throw ValidationException (400)
        end

        Controller->>Controller: extract userId = jwt.getSubject()
    end

    %% red highlight
    rect rgba(255,0,0,0.15)
    note over Controller,LedgerRepo: Application Logging
        Controller->>Service: createLedger(ledgersEntryDTO, userId)

        Service->>TxManager: begin @Transactional

        Service->>Service: ledgerUuid = UUID.randomUUID()

        Service->>LedgerMapper: map(ledgersEntryDTO)
        LedgerMapper->>LedgerMapper: ModelMapper.map(dto → Ledgers)<br/>setCreatedAt / setUpdatedAt
        LedgerMapper-->>Service: Ledgers (partial)

        Service->>Service: ledger.setId(ledgerUuid)<br/>ledger.setOwnerId(userId)

        Service->>LedgerRepo: createLedger(ledger)
    end

    %% green highlight
    rect rgba(0,255,0,0.15)
    note over LedgerRepo,DBs: DB Logging
        LedgerRepo->>DB: INSERT INTO ledgers<br/>(id, date, description, created_at, updated_at, owner_id)
        alt DB error
            DB-->>LedgerRepo: Exception
            LedgerRepo-->>Service: throw JooqOperationException
            Service-->>TxManager: rollback
            TxManager-->>Client: 500 / propagated exception
        end
        DB-->>LedgerRepo: OK
        LedgerRepo-->>Service: void

        Service->>ItemsMapper: map(ledgersEntryDTO)
        ItemsMapper->>ItemsMapper: stream ledgerItems DTOs<br/>ModelMapper.map each → LedgerItems<br/>setCreatedAt / setUpdatedAt
        ItemsMapper-->>Service: List<LedgerItems>
    end

    loop for each LedgerItem
        %% red highlight
        rect rgba(255,0,0,0.15)
            Service->>Service: item.setId(UUID.randomUUID())<br/>item.setLedgerId(ledgerUuid)
            Service->>ItemsRepo: createLedgerItems(ledgerItem)
        end

        %% green highlight
        rect rgba(0,255,0,0.15)
            ItemsRepo->>DB: INSERT INTO ledger_items<br/>(id, ledger_id, coa, amount, type, created_at, updated_at)
            alt DB error
                DB-->>ItemsRepo: Exception
                ItemsRepo-->>Service: throw JooqOperationException
                Service-->>TxManager: rollback (all inserts rolled back)
                TxManager-->>Client: 500 / propagated exception
            end
            DB-->>ItemsRepo: OK
            ItemsRepo-->>Service: void
        end
    end

    Service-->>TxManager: commit
    TxManager->>DB: COMMIT

    Service-->>Controller: void
    Controller-->>Client: 200 OK — "Successfully created new ledger"
```

## Flow Summary

| Step | Who                     | What                                              | Log Level | Log Message                                                  |
| :--: | ----------------------- | ------------------------------------------------- | :-------: | ------------------------------------------------------------ |
|  1   | Client → Security       | `POST /ledger` with `Authorization: Bearer <JWT>` |     —     | _(handled by framework)_                                     |
|  2   | Security                | Validates JWT; extracts `Jwt` principal           |  `WARN`   | `"JWT validation failed: {reason}"`                          |
|  3   | Controller              | Validates `LedgersEntryDTO` via `@Validated`      |  `ERROR`  | `"Validation errors: {bindingResult.getAllErrors()}"`        |
|  4   | Controller              | Extracts `userId` from `jwt.getSubject()`         |     —     | —                                                            |
|  5   | Controller → Service    | Calls `createLedger(dto, userId)`                 |  `DEBUG`  | `"New ledger created: {ledgersEntryDTO} for user: {userId}"` |
|  6   | `LedgerMapper`          | Maps DTO → `Ledgers` POJO                         |     —     | —                                                            |
|  7   | Service                 | Sets `id` + `ownerId`; generates `ledgerUuid`     |     —     | —                                                            |
|  8   | `LedgerRepository`      | jOOQ `INSERT INTO ledgers` — **success**          |  `DEBUG`  | `"Ledger created: {ledger}"`                                 |
|  8e  | `LedgerRepository`      | jOOQ `INSERT INTO ledgers` — **DB error**         |  `ERROR`  | `"Error creating ledger"` _(+ exception stack)_              |
|  9   | `LedgerItemsMapper`     | Maps each item DTO → `LedgerItems` list           |     —     | —                                                            |
|  10  | Service (loop)          | Assigns `UUID` + `ledgerId` to each item          |  `DEBUG`  | `"ledgerItem created: {ledgerItem}"`                         |
|  11  | `LedgerItemsRepository` | jOOQ `INSERT INTO ledger_items` — **success**     |  `DEBUG`  | _(logged via step 10 before insert)_                         |
| 11e  | `LedgerItemsRepository` | jOOQ `INSERT INTO ledger_items` — **DB error**    |  `ERROR`  | `"Error creating ledger items"` _(+ exception stack)_        |
|  12  | Transaction             | Commits or full rollback on exception             |     —     | —                                                            |
|  13  | Controller              | Returns `200 OK`                                  |  `DEBUG`  | `"New ledger created: {ledgersEntryDTO} for user: {userId}"` |

### Log Level Guidelines

| Level   | When to use                                                                                            |
| ------- | ------------------------------------------------------------------------------------------------------ |
| `DEBUG` | Normal successful operations; method entry/exit with key identifiers (`ledgerId`, `userId`)            |
| `INFO`  | Significant business events worth tracking in production (e.g. ledger committed)                       |
| `WARN`  | Recoverable issues or security-relevant events (e.g. JWT rejected, unauthorised access attempt)        |
| `ERROR` | Unexpected failures that cause the request to fail; always attach the exception object for stack trace |

### Recommended Production Log Format

```text
[LEVEL] [class#method] message — key=value pairs
```

**Examples:**

```text
DEBUG LedgerCommandService#createLedger  Ledger created: id=3fa85f64, ownerId=user-001
DEBUG LedgerCommandService#createLedger  ledgerItem created: id=7b3c1a22, ledgerId=3fa85f64, coa=1010, type=DEBIT
ERROR LedgerRepository#createLedger      Error creating ledger — exception attached
WARN  LedgersController#newLedger        Validation errors: [field 'date' must not be null]
```

> **Note:** Never log sensitive financial amounts at `DEBUG` in production — gate behind `log.isDebugEnabled()` or use `INFO` with redaction.
