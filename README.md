#  XyloPhone for IOS

Development Setup Requirements

Software Requirements
- Xcode
- install carthage
- cocoa pods

Prepare project

1. Run carthage to pull dependencies

carthage update

2. Run pod to update PyTorch dependencies

pod update

3. Place a copy of model.zip into

<project>/XyloPhoneIOS/model/model.zip

The model itself is not included in this repo as it is really big (40-100MB) see below
on how it is generated.


# Notes on building the model.zip file

The model.zip has a structure as follows:

/model.zip
    /reference
        |- <species name 1>
        |    \ image1.png
        L- <species name 2>
             \ image2.png
    labels.txt
    model.json
    model.txt
    model.pt
    species_database.json

Note that this zip file structure is built by the Machine Learning Python script that
can be found here:

https://github.com/jedld/fips-wood-id-model/tree/master/model

This zip file contains the Pytorch "Mobile" model as well as various information about
the supported species and "reference" images that will be shown in the detail page.

Building and Training the Pytorch model requires prior knowledge on the
PyTorch and Pytorch Mobile Framework for IOS. The process for training a model
is beyond the scope of this README however the important thing to
note is that the PyTorch version used in generating the model must be the same as the one
defined in Podfile, differences can causes crashes.

# Adding automatic support for other IOS devices

There is a phone_settings.json file where you can add default values for
the camera settings depending on the detected phone model.


