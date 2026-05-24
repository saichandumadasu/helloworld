import os

import httpx
from fastapi import FastAPI, HTTPException

app = FastAPI()

HELLO_URL = os.getenv("HELLO_URL", "http://localhost:8001/hello")
MIDDLE_URL = os.getenv("MIDDLE_URL", "http://localhost:8003/middle")
WORLD_URL = os.getenv("WORLD_URL", "http://localhost:8002/world")



@app.get("/")
async def gateway():
    async with httpx.AsyncClient() as client:
        try:
            hello = await client.get(HELLO_URL)
            middle = await client.get(MIDDLE_URL)
            world = await client.get(WORLD_URL)
        except httpx.RequestError as exc:
            raise HTTPException(status_code=503, detail=f"Service unreachable: {exc}")
    hello_msg = hello.json()["message"]
    middle_msg = middle.json()["message"]   
    world_msg = world.json()["message"]
    return {"message": f"{hello_msg}, {middle_msg}, {world_msg}!"}

@app.get("/health")
def health():
    status = "healthy"
    if not all([check_service(HELLO_URL), check_service(MIDDLE_URL), check_service(WORLD_URL)]):
        status = "unhealthy"
    return {"status": status}

def check_service(url):
    try:
        response = httpx.get(url, timeout=2)
        return response.status_code == 200
    except httpx.RequestError:
        return False