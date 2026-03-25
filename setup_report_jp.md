# OpenTelemetry Logback 設定レポート

このドキュメントでは、Double Accounting System (CQRS) における OpenTelemetry (OTel) Logback アペンダーの導入手順と設定内容について説明します。

## 1. 概要

システムのログを OTLP (OpenTelemetry Protocol) 経由でバックエンド（OTel Collector, Datadog, Grafana 等）に転送するため、既存のファイル出力アペンダーに加えて `OpenTelemetryAppender` を追加しました。

対象サービス:
- `springboot_cqrs_command`
- `springboot_cqrs_query`

## 2. 依存関係の追加 (`pom.xml`)

各サービスの `pom.xml` に以下の依存関係を追加しました。

```xml
<!-- OTel Logback Appender -->
<dependency>
    <groupId>io.opentelemetry.instrumentation</groupId>
    <artifactId>opentelemetry-logback-appender-1.0</artifactId>
    <version>2.13.0-alpha</version>
</dependency>
<!-- OTel SDK (マニュアル設定用) -->
<dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-sdk</artifactId>
    <version>1.46.0</version>
</dependency>
<dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-exporter-otlp</artifactId>
    <version>1.46.0</version>
</dependency>
```

## 3. Logback 設定 (`logback-spring.xml`)

`src/main/resources/logback-spring.xml` を作成し、3つのアペンダーを構成しました。

1.  **MSG_FILE**: `logs/app.log` へメッセージのみ出力（スタックトレースなし）。
2.  **ERR_FILE**: `logs/app-errors.log` へスタックトレースを含むエラーを出力。
3.  **OTEL**: OpenTelemetry 経由で構造化データとしてログを転送。

`OTEL` アペンダーの設定では、以下の属性をキャプチャするように構成しています：
- スレッド情報 (`captureExperimentalAttributes`)
- コード属性（クラス名、メソッド名、行番号） (`captureCodeAttributes`)
- MDC 属性 (`captureMdcAttributes`)
- 例外マーカー (`captureMarkerAttribute`)

## 4. Java による初期化設定 (`LoggingConfig.java`)

OTel Java Agent を使用しない場合でもログが正しく転送されるよう、Spring Bean として `OpenTelemetry` を定義し、起動時に `OpenTelemetryAppender.install(sdk)` を呼び出す設定クラスを追加しました。

```java
@Configuration
public class LoggingConfig {
    // ... OpenTelemetry Bean 定義 ...

    @PostConstruct
    public void init() {
        if (openTelemetry instanceof OpenTelemetrySdk sdk) {
            OpenTelemetryAppender.install(sdk);
        }
    }
}
```

各サービスごとに `service.name` 属性（`ledger-command` / `ledger-query`）を設定しています。

## 5. 動作確認

- アプリケーション起動時に `logs/` ディレクトリが作成され、`app.log` にログが出力されることを確認してください。
- エラーログ発生時に `app-errors.log` にスタックトレースが出力されることを確認してください。
- OTLP エクスポーターはデフォルトで `localhost:4317` (gRPC) を宛先とします。環境に合わせて設定を変更する場合は `LoggingConfig.java` の `OtlpGrpcLogRecordExporter` 部分を調整してください。
