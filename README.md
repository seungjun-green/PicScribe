# Pic Scribe

## About the project

I made a image captioning model by using ViT as encoder and Transformer Decoder as decoder, and training it with COCO2017 dataset. 
Then deployed these models to iOS app by converting these models into CoreML and building an iOS app with SwiftUI. You can test this iOS app by clonnig this repo or u can just simply try out this model on [HuggingFace](https://huggingface.co/Seungjun/image_captioner).

[Converting two PyTorch models into CoreML models](https://github.com/seungjun-green/PicScribe/blob/master/Convert_PyTorch_Models_to_CoreML_Models.ipynb)

[CoreML model - encoder](https://github.com/seungjun-green/PicScribe/tree/master/Pic%20Scribe/Pic%20Scribe/VIT_iOS_Encoder_v10.mlpackage)

[CoreML model - decoder](https://github.com/seungjun-green/PicScribe/tree/master/Pic%20Scribe/Pic%20Scribe/iOS_Decoder_V14.mlpackage)


## More Details about the model
The image is passed to ViT_b_32(classification layer removed), and this outputs (N, 768) tensor. and this is repeated to (N, 32, 768) so that it can be passed as K, V to CrossMultiHeadAttention blcok in Decoder. The the decoder has 44.3M parameters. The input shape of decoder is (N, max_length=32), and output shape of the decoder is (N, max_length=32, vocab_size). The tokenizer I used is BERT. 

For more details about how the model is trained u can find at here:
[Creating Image Captioning model using PyTorch](https://github.com/seungjun-green/PicScribe/blob/master/Make%20Image%20Captioner%20Model.ipynb)

Then I converted these modles to CoreML models. 

## How to use this project

Create a folder in ur computer and move to it then type this:
git clone https://github.com/seungjun-green/PicScribe.git
cd Pic Scribe/Pic Scribe.xcodeproj
then open this xcode project and build on ur mac machine.

## Model Evaluation





