import asyncio

import httpx


class SyncASGIClient:
    def __init__(self, app, base_url: str = "http://testserver"):
        self._app = app
        self._base_url = base_url

    def get(self, path: str, **kwargs) -> httpx.Response:
        return self.request("GET", path, **kwargs)

    def post(self, path: str, **kwargs) -> httpx.Response:
        return self.request("POST", path, **kwargs)

    def request(self, method: str, path: str, **kwargs) -> httpx.Response:
        return asyncio.run(self._request(method, path, **kwargs))

    async def _request(self, method: str, path: str, **kwargs) -> httpx.Response:
        transport = httpx.ASGITransport(app=self._app)
        async with httpx.AsyncClient(transport=transport, base_url=self._base_url) as client:
            return await client.request(method, path, **kwargs)
