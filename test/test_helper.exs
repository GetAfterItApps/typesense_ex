Mox.defmock(Typesense.MockHttp, for: Typesense.Http)
Application.put_env(:typesense_ex, :http_library, Typesense.MockHttp)

Mox.defmock(Typesense.MockPool, for: Typesense.Pool)
Application.put_env(:typesense_ex, :pool, Typesense.MockPool)

Mox.defmock(Typesense.MockNode, for: Typesense.Node)
Application.put_env(:typesense_ex, :node, Typesense.MockNode)

Mox.defmock(Typesense.MockRequestConfig, for: Typesense.RequestConfig)
Application.put_env(:typesense_ex, :request_config, Typesense.MockRequestConfig)

ExUnit.start()
