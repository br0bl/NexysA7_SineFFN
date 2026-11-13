# ffn_cocotb.py additional dependencies

1. Set `MODEL_PATH` to your model's location:

    ```python
    MODEL_PATH = Path("/path/to/your/hello_world_int8.tflite")
    ```

2. `$readmemh` resolves relative filenames from the simulator's working directory, add memory files or create symbolic links
