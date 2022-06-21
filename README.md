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

The model itself is not included in this repo as it is really big (40-100MB)

