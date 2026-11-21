from PIL import Image, ImageDraw, ImageFilter
import math

# Reference image
img = Image.open('/home/antigravity/image.png').convert('RGBA')
W, H = img.size

# 1. Background layer: full atmospheric painting (reference backdrop)
img.save('/home/antigravity/akasha_project/assets/sprites/world_backdrop.png')

# 2. Soul sprite: precise radiant spirit inspired by the protagonist
# Size: 128x128
soul_img = Image.new('RGBA', (128, 128), (0, 0, 0, 0))
draw = ImageDraw.Draw(soul_img)

# Outer warm bloom
for r in range(40, 5, -3):
    alpha = int(45 * (1.0 - r / 40.0))
    draw.ellipse([64 - r, 50 - r, 64 + r, 50 + r], fill=(255, 230, 150, alpha))

# Inner intense white-gold core
for r in range(22, 2, -2):
    alpha = int(180 * (1.0 - r / 22.0))
    draw.ellipse([64 - r, 50 - r, 64 + r, 50 + r], fill=(255, 250, 220, alpha))

# Core silhouette body
# Head & halo
draw.ellipse([58, 26, 70, 38], fill=(255, 255, 255, 255))
# Crown / halo tip
draw.polygon([(64, 18), (61, 26), (67, 26)], fill=(255, 245, 200, 255))
# Body / robes tapering down
draw.polygon([(60, 36), (68, 36), (72, 70), (56, 70)], fill=(255, 255, 255, 255))
# Flowing hem
draw.polygon([(56, 70), (64, 76), (72, 70), (64, 72)], fill=(255, 245, 200, 255))
# Floating scarf / ribbon to the left
scarf = [(59, 44), (46, 50), (32, 54), (20, 52), (18, 54), (32, 58), (48, 54), (59, 48)]
draw.polygon(scarf, fill=(255, 245, 210, 220))

soul_img.save('/home/antigravity/akasha_project/assets/sprites/soul.png')

# 3. Particle / Spark sprite (32x32)
spark = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
sdraw = ImageDraw.Draw(spark)
for r in range(14, 1, -2):
    a = int(160 * (1.0 - r / 14.0))
    sdraw.ellipse([16 - r, 16 - r, 16 + r, 16 + r], fill=(255, 215, 100, a))
sdraw.ellipse([13, 13, 19, 19], fill=(255, 255, 255, 255))
spark.save('/home/antigravity/akasha_project/assets/sprites/spark.png')

print("Assets successfully generated!")
