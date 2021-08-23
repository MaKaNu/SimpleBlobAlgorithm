# SimpleBlobAlgorithm
This is a simple Blob Algorithm for Matlab Video Labeler

# Example
![ezgif com-gif-maker](https://user-images.githubusercontent.com/32844273/130474954-cef5aee4-3ba7-43a8-8a39-ee796571e101.gif)

# Installation
Copy the complete folder ```+vision/+labeler/``` on a directory on the matlab path

# Usage
- Launch the MATLAB video labeler app
  - from menu: "APPS > IMAGE PROCESSING AND COMPUTER VISION > Video Labeler"
  - from console: ```>> videoLabeler```
- Load your Video Sequence
- Make shure that:
  - the sequence is in correct order
  - all object are good visual
  - the background has low saturation
  - the object count doesn't change in the sequence
- Create ROIs for all objects and select them with ```ctrl + click```
- Refresh the Algorithm list and choose "Simple Blob Algorithm"
- Start the Algorithm with the "Play" button.
- If the Algorithm fails: try again with different values for Area Threshold and Dilation Size in the Settings

And remember: This is a bare simple algorithm and is far from stable 😏



