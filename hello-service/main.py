from fastapi import FastAPI
app = FastAPI()


@app.get("/hello")
def hello():
    return {"message": "Hello sai"}

@app.get("/")
def root():
    return {"message": "Welcome to hello!"}

@app.get("/hello/{name}")
def hello_name(name: str):
    return {"message": f"Hello {name}!"}