# Pic Scribe

[Demo Video(testing app on iPhone 13 Pro)](https://x.com/i/status/1797300456185864329)

## About the project
This project implements an image captioning model. The model uses a Vision Transformer (ViT) as the encoder and a Transformer decoder as the decoder. It's trained on the COCO2017 dataset. The trained models are then deployed to an iOS app built with SwiftUI. You can test the app by cloning this repository or just try out the model with uplaoded weights.

## More Details about the model
The image is first processed by a ViT_b_32 model (with the classification layer removed). This outputs a tensor of size (N, 768). This tensor is then reshaped to (N, 32, 768) to be compatible with the CrossMultiHeadAttention block in the decoder. The decoder itself has 44.3 million parameters. It takes an input with a shape of (N, max_length=32) and outputs a tensor with a shape of (N, max_length=32, vocab_size). BERT tokenizer is used for text preprocessing.

Model Training Notebook: [Google Colab]()

## Converting PyTorch Models to CoreML
For details on converting these models into CoreML models and testing them, please refer to the following resources:
[Converting two PyTorch models into CoreML models](https://github.com/seungjun-green/PicScribe/blob/master/Convert_PyTorch_Models_to_CoreML_Models.ipynb)

[CoreML model - encoder](https://github.com/seungjun-green/PicScribe/tree/master/Pic%20Scribe/Pic%20Scribe/VIT_iOS_Encoder_v10.mlpackage)

[CoreML model - decoder](https://github.com/seungjun-green/PicScribe/tree/master/Pic%20Scribe/Pic%20Scribe/iOS_Decoder_V14.mlpackage)

## How to use this project

Create a folder in your local machine and move to it then type this:
```
git clone https://github.com/seungjun-green/PicScribe.git
cd "Pic Scribe/Pic Scribe.xcodeproj"
```
Then open Open the Pic Scribe.xcodeproj file using Xcode.



