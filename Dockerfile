FROM oracle/graalvm-ce AS graalvm-ce

RUN yum install -y git \
    && gu install native-image
RUN curl -o /usr/bin/lein https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein \
    && chmod a+x /usr/bin/lein

RUN cd / \
    && git clone --depth=1 https://github.com/snoe/clojure-lsp.git \
    && cd clojure-lsp \
    && lein uberjar \
    && mkdir native-image \
    && mv target/clojure-lsp-0.1.0-SNAPSHOT-standalone.jar native-image/ \
    && cd native-image \
    && native-image \
        -jar clojure-lsp-0.1.0-SNAPSHOT-standalone.jar \
        -H:Name=clojure-lsp \
        -H:+ReportExceptionStackTraces \
        -J-Dclojure.spec.skip-macros=true \
        -J-Dclojure.compiler.direct-linking=true \
        -H:Log=registerResource: \
        --verbose \
        --no-fallback \
        --no-server \
        --report-unsupported-elements-at-runtime \
        --initialize-at-build-time \
        --static \
        -J-Xms4g \
        -J-Xmx16g

FROM scratch

COPY --from=graalvm-ce /clojure-lsp/native-image/clojure-lsp /clojure-lsp

ENTRYPOINT ["/clojure-lsp"]
