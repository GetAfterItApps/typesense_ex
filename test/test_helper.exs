Mox.defmock(Typesense.MockHttp, for: Typesense.Http)
Application.put_env(:typesense_ex, :http_library, Typesense.MockHttp)

Mox.defmock(Typesense.MockRequest, for: Typesense.Request)
Application.put_env(:typesense_ex, :request, Typesense.MockRequest)

ExUnit.start()
