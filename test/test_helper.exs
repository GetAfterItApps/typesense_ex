Mox.defmock(TypesenseEx.MockHttp, for: TypesenseEx.Http)
Application.put_env(:typesense_ex, :http_library, TypesenseEx.MockHttp)

Mox.defmock(TypesenseEx.MockPool, for: TypesenseEx.Pool)
Application.put_env(:typesense_ex, :pool, TypesenseEx.MockPool)

Mox.defmock(TypesenseEx.MockNode, for: TypesenseEx.Node)
Application.put_env(:typesense_ex, :node, TypesenseEx.MockNode)

Mox.defmock(TypesenseEx.MockRequestConfig, for: TypesenseEx.RequestConfig)
Application.put_env(:typesense_ex, :request_config, TypesenseEx.MockRequestConfig)

ExUnit.start()
