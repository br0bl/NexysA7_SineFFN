import numpy as np
import logging

import ai_edge_litert.interpreter as tflite_interp
from ai_edge_litert.interpreter import OpResolverType

def invoke_tflite_interpreter(input_shape, interpreter, x_value, input_index, output_index):
    input_data = np.reshape(x_value, input_shape)
    interpreter.set_tensor(input_index, input_data)
    interpreter.invoke()
    tflite_output = interpreter.get_tensor(output_index)
    y_quantized = np.reshape(tflite_output, -1)[0]
    return y_quantized

def get_tflite_prediction(model_path, x_values):
    kwargs = {"model_path": str(model_path)}
    if OpResolverType is not None:
        kwargs["experimental_op_resolver_type"] = OpResolverType.BUILTIN_REF
    else:
        logging.warning(
        "Could not find OpResolverType. Reference kernels might not be used."
        )

    tflite_interpreter = tflite_interp.Interpreter(**kwargs)
    tflite_interpreter.allocate_tensors()

    input_details = tflite_interpreter.get_input_details()[0]
    output_details = tflite_interpreter.get_output_details()[0]
    input_shape = np.array(input_details.get('shape'))

    x_values = np.asarray(x_values, dtype=input_details["dtype"])
    y_predictions = np.empty(x_values.size, dtype=output_details["dtype"])

    for i, x_value in enumerate(x_values):
        y_predictions[i] = invoke_tflite_interpreter(
        input_shape,
        tflite_interpreter,
        x_value,
        input_details['index'],
        output_details['index'],
        )
    return y_predictions

def get_tflite_tensors(model_path, x_value):
    kwargs = {
        "model_path": str(model_path),
        "experimental_preserve_all_tensors": True,
    }

    if OpResolverType is not None:
        kwargs["experimental_op_resolver_type"] = OpResolverType.BUILTIN_REF
    else:
        logging.warning(
        "Could not find OpResolverType. Reference kernels might not be used."
        )

    interpreter = tflite_interp.Interpreter(**kwargs)
    interpreter.allocate_tensors()

    input_details = interpreter.get_input_details()[0]
    input_data = np.full(
        input_details["shape"],
        x_value,
        dtype=input_details["dtype"],
    )

    interpreter.set_tensor(input_details["index"], input_data)
    interpreter.invoke()

    tensors = {}

    for detail in interpreter.get_tensor_details():
        tensor = interpreter.get_tensor(detail["index"])
        tensors[detail["name"]] = tensor.copy()

    return tensors

def get_tflite_tensor_details(model_path):
    interpreter = tflite_interp.Interpreter(model_path=str(model_path))
    interpreter.allocate_tensors()
    return interpreter.get_tensor_details()