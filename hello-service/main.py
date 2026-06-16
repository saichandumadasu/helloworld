from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator

app = FastAPI()

Instrumentator().instrument(app).expose(app)


@app.get("/hello")
def hello():
    return {"message": "Hello sai"}

@app.get("/")
def root():
    return {"message": "Welcome to hello!"}

@app.get("/hello/{name}")
def hello_name(name: str):
    return {"message": f"Hello {name}!"}