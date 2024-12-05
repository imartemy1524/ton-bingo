import os
from PIL import Image, ImageDraw, ImageFont

# Define the font and size
font = ImageFont.truetype("arial.ttf", 50)

# Generate digits from 1 to 99
for i in range(1, 100):
    # Create a new image with white background
    image = Image.new('RGBA', (100, 100))
    draw = ImageDraw.Draw(image)

    # Get the size of the text to be drawn
    text = str(i)
    text_bbox = draw.textbbox((0, 0), text, font=font)
    text_width, text_height = text_bbox[2] - text_bbox[0], text_bbox[3] - text_bbox[1]

    # Calculate the position to center the text
    position = ((100 - text_width) // 2, (100 - text_height) // 2 - 7)

    # Draw the text on the image
    draw.text(position, text, fill='white', font=font)

    # Save the image
    image.save(f'./{i}.webp')

print("Images generated and saved in the 'images' folder.")