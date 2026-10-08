import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

def create_smooth_icon(size=1024, scale=4):
    w = size * scale
    h = size * scale
    
    # 1. Base App Icon (with rich gradient background & subtle glow)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Gradient background
    c_top = (16, 42, 67)       # #102A43 deep navy
    c_bottom = (8, 24, 40)     # #081828 darker navy
    
    for y in range(h):
        r = int(c_top[0] + (c_bottom[0] - c_top[0]) * (y / h))
        g = int(c_top[1] + (c_bottom[1] - c_top[1]) * (y / h))
        b = int(c_top[2] + (c_bottom[2] - c_top[2]) * (y / h))
        draw.line([(0, y), (w, y)], fill=(r, g, b, 255))
        
    # Subtle inner glow / radial circle
    cx, cy = w / 2, h / 2
    
    # Outer ambient glow behind the logo
    glow_img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_img)
    glow_radius = int(w * 0.38)
    glow_draw.ellipse(
        [cx - glow_radius, cy - glow_radius, cx + glow_radius, cy + glow_radius],
        fill=(0, 191, 165, 45) # #00BFA5 teal glow
    )
    glow_img = glow_img.filter(ImageFilter.GaussianBlur(radius=80 * scale))
    img = Image.alpha_composite(img, glow_img)
    draw = ImageDraw.Draw(img)

    # Draw Emblem: Mindful Lotus / Zen Eye & Leaf geometry
    # Central ring & organic mindfulness leaves
    # We will draw layered crisp arcs and polygons
    
    # 1. Outer stylized lotus petals / zen arcs
    teal_primary = (0, 191, 165, 255)    # #00BFA5
    cyan_accent = (0, 229, 255, 255)     # #00E5FF
    mint_light = (224, 242, 241, 255)    # #E0F2F1
    
    # Center lotus / leaf shapes
    # Central leaf (vertical)
    leaf_w = int(w * 0.13)
    leaf_h = int(h * 0.34)
    leaf_cx = cx
    leaf_cy = cy - int(h * 0.02)
    
    # Draw central teardrop / leaf
    def draw_petal(draw_obj, center_x, center_y, width, height, angle_deg, color):
        # Create a single petal on a transparent canvas and rotate
        p_img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        p_draw = ImageDraw.Draw(p_img)
        
        # Points for a smooth almond / leaf
        top_y = center_y - height / 2
        bottom_y = center_y + height / 2
        left_x = center_x - width / 2
        right_x = center_x + width / 2
        
        # Draw curved leaf shape with bezier-like polygon
        points = []
        steps = 40
        for i in range(steps + 1):
            t = i / steps
            # left curve from bottom to top
            cur_y = bottom_y - t * height
            # quadratic bump
            curve_x = center_x - (width / 2) * math.sin(t * math.pi)
            points.append((curve_x, cur_y))
        for i in range(steps + 1):
            t = i / steps
            # right curve from top to bottom
            cur_y = top_y + t * height
            curve_x = center_x + (width / 2) * math.sin(t * math.pi)
            points.append((curve_x, cur_y))
            
        p_draw.polygon(points, fill=color)
        if angle_deg != 0:
            p_img = p_img.rotate(angle_deg, center=(center_x, center_y), resample=Image.BICUBIC)
        return p_img

    # Draw left and right outer wings/petals (Mindfulness / Zen wings)
    p_left_outer = draw_petal(draw, cx - int(w * 0.16), cy + int(h * 0.04), int(leaf_w * 0.9), int(leaf_h * 0.8), -52, teal_primary)
    p_right_outer = draw_petal(draw, cx + int(w * 0.16), cy + int(h * 0.04), int(leaf_w * 0.9), int(leaf_h * 0.8), 52, teal_primary)
    
    # Left and right inner petals
    p_left_mid = draw_petal(draw, cx - int(w * 0.09), cy + int(h * 0.01), int(leaf_w * 0.95), int(leaf_h * 0.92), -26, cyan_accent)
    p_right_mid = draw_petal(draw, cx + int(w * 0.09), cy + int(h * 0.01), int(leaf_w * 0.95), int(leaf_h * 0.92), 26, cyan_accent)
    
    # Center tall petal (shining mint teal)
    p_center = draw_petal(draw, cx, leaf_cy, int(leaf_w * 1.05), leaf_h, 0, mint_light)
    
    # Merge petals
    img = Image.alpha_composite(img, p_left_outer)
    img = Image.alpha_composite(img, p_right_outer)
    img = Image.alpha_composite(img, p_left_mid)
    img = Image.alpha_composite(img, p_right_mid)
    img = Image.alpha_composite(img, p_center)
    
    # Mindful focus dot / pearl at the core
    draw = ImageDraw.Draw(img)
    dot_r = int(w * 0.042)
    dot_cy = cy + int(h * 0.17)
    draw.ellipse([cx - dot_r, dot_cy - dot_r, cx + dot_r, dot_cy + dot_r], fill=(0, 229, 255, 255))
    
    # Supporting cradle arc (zen ring / smiling digital shield)
    arc_box = [cx - int(w * 0.28), cy - int(h * 0.1), cx + int(w * 0.28), cy + int(h * 0.28)]
    draw.arc(arc_box, start=30, end=150, fill=teal_primary, width=int(14 * scale))
    
    # Downscale for crisp anti-aliasing
    final_img = img.resize((size, size), Image.Resampling.LANCZOS)
    return final_img

def create_foreground_icon(size=1024, scale=4):
    w = size * scale
    h = size * scale
    
    # Adaptive Icon Foreground (Transparent background with safe padding ~ 66% area)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    cx, cy = w / 2, h / 2
    
    # Slightly scaled to fit Android safe zone circle (66% of 1024 = ~670px)
    ratio = 0.82
    
    teal_primary = (0, 191, 165, 255)
    cyan_accent = (0, 229, 255, 255)
    mint_light = (224, 242, 241, 255)
    
    leaf_w = int(w * 0.13 * ratio)
    leaf_h = int(h * 0.34 * ratio)
    leaf_cy = cy - int(h * 0.02 * ratio)
    
    def draw_petal(center_x, center_y, width, height, angle_deg, color):
        p_img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        p_draw = ImageDraw.Draw(p_img)
        top_y = center_y - height / 2
        bottom_y = center_y + height / 2
        points = []
        steps = 40
        for i in range(steps + 1):
            t = i / steps
            cur_y = bottom_y - t * height
            curve_x = center_x - (width / 2) * math.sin(t * math.pi)
            points.append((curve_x, cur_y))
        for i in range(steps + 1):
            t = i / steps
            cur_y = top_y + t * height
            curve_x = center_x + (width / 2) * math.sin(t * math.pi)
            points.append((curve_x, cur_y))
            
        p_draw.polygon(points, fill=color)
        if angle_deg != 0:
            p_img = p_img.rotate(angle_deg, center=(center_x, center_y), resample=Image.BICUBIC)
        return p_img

    p_left_outer = draw_petal(cx - int(w * 0.16 * ratio), cy + int(h * 0.04 * ratio), int(leaf_w * 0.9), int(leaf_h * 0.8), -52, teal_primary)
    p_right_outer = draw_petal(cx + int(w * 0.16 * ratio), cy + int(h * 0.04 * ratio), int(leaf_w * 0.9), int(leaf_h * 0.8), 52, teal_primary)
    p_left_mid = draw_petal(cx - int(w * 0.09 * ratio), cy + int(h * 0.01 * ratio), int(leaf_w * 0.95), int(leaf_h * 0.92), -26, cyan_accent)
    p_right_mid = draw_petal(cx + int(w * 0.09 * ratio), cy + int(h * 0.01 * ratio), int(leaf_w * 0.95), int(leaf_h * 0.92), 26, cyan_accent)
    p_center = draw_petal(cx, leaf_cy, int(leaf_w * 1.05), leaf_h, 0, mint_light)
    
    img = Image.alpha_composite(img, p_left_outer)
    img = Image.alpha_composite(img, p_right_outer)
    img = Image.alpha_composite(img, p_left_mid)
    img = Image.alpha_composite(img, p_right_mid)
    img = Image.alpha_composite(img, p_center)
    
    draw = ImageDraw.Draw(img)
    dot_r = int(w * 0.042 * ratio)
    dot_cy = cy + int(h * 0.17 * ratio)
    draw.ellipse([cx - dot_r, dot_cy - dot_r, cx + dot_r, dot_cy + dot_r], fill=(0, 229, 255, 255))
    
    arc_box = [cx - int(w * 0.28 * ratio), cy - int(h * 0.1 * ratio), cx + int(w * 0.28 * ratio), cy + int(h * 0.28 * ratio)]
    draw.arc(arc_box, start=30, end=150, fill=teal_primary, width=int(14 * scale * ratio))
    
    final_img = img.resize((size, size), Image.Resampling.LANCZOS)
    return final_img

def create_splash_logo(size=512, scale=4):
    w = size * scale
    h = size * scale
    
    # Splash Logo (Transparent background with crisp glowing Mind Driji icon & text)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    cx, cy = w / 2, h * 0.44
    
    ratio = 0.9
    teal_primary = (0, 191, 165, 255)
    cyan_accent = (0, 229, 255, 255)
    mint_light = (224, 242, 241, 255)
    
    leaf_w = int(w * 0.13 * ratio)
    leaf_h = int(h * 0.34 * ratio)
    leaf_cy = cy - int(h * 0.02 * ratio)
    
    def draw_petal(center_x, center_y, width, height, angle_deg, color):
        p_img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        p_draw = ImageDraw.Draw(p_img)
        top_y = center_y - height / 2
        bottom_y = center_y + height / 2
        points = []
        steps = 40
        for i in range(steps + 1):
            t = i / steps
            cur_y = bottom_y - t * height
            curve_x = center_x - (width / 2) * math.sin(t * math.pi)
            points.append((curve_x, cur_y))
        for i in range(steps + 1):
            t = i / steps
            cur_y = top_y + t * height
            curve_x = center_x + (width / 2) * math.sin(t * math.pi)
            points.append((curve_x, cur_y))
            
        p_draw.polygon(points, fill=color)
        if angle_deg != 0:
            p_img = p_img.rotate(angle_deg, center=(center_x, center_y), resample=Image.BICUBIC)
        return p_img

    p_left_outer = draw_petal(cx - int(w * 0.16 * ratio), cy + int(h * 0.04 * ratio), int(leaf_w * 0.9), int(leaf_h * 0.8), -52, teal_primary)
    p_right_outer = draw_petal(cx + int(w * 0.16 * ratio), cy + int(h * 0.04 * ratio), int(leaf_w * 0.9), int(leaf_h * 0.8), 52, teal_primary)
    p_left_mid = draw_petal(cx - int(w * 0.09 * ratio), cy + int(h * 0.01 * ratio), int(leaf_w * 0.95), int(leaf_h * 0.92), -26, cyan_accent)
    p_right_mid = draw_petal(cx + int(w * 0.09 * ratio), cy + int(h * 0.01 * ratio), int(leaf_w * 0.95), int(leaf_h * 0.92), 26, cyan_accent)
    p_center = draw_petal(cx, leaf_cy, int(leaf_w * 1.05), leaf_h, 0, teal_primary)
    
    img = Image.alpha_composite(img, p_left_outer)
    img = Image.alpha_composite(img, p_right_outer)
    img = Image.alpha_composite(img, p_left_mid)
    img = Image.alpha_composite(img, p_right_mid)
    img = Image.alpha_composite(img, p_center)
    
    draw = ImageDraw.Draw(img)
    dot_r = int(w * 0.042 * ratio)
    dot_cy = cy + int(h * 0.17 * ratio)
    draw.ellipse([cx - dot_r, dot_cy - dot_r, cx + dot_r, dot_cy + dot_r], fill=teal_primary)
    
    arc_box = [cx - int(w * 0.28 * ratio), cy - int(h * 0.1 * ratio), cx + int(w * 0.28 * ratio), cy + int(h * 0.28 * ratio)]
    draw.arc(arc_box, start=30, end=150, fill=teal_primary, width=int(14 * scale * ratio))
    
    # Try loading a system font for MIND DRIJI branding
    try:
        font_main = ImageFont.truetype("arialbd.ttf", int(38 * scale))
        font_sub = ImageFont.truetype("arial.ttf", int(18 * scale))
    except Exception:
        font_main = ImageFont.load_default()
        font_sub = ImageFont.load_default()
        
    text_main = "MIND DRIJI"
    text_sub = "Digital Wellness Companion"
    
    bbox_m = draw.textbbox((0, 0), text_main, font=font_main)
    w_m = bbox_m[2] - bbox_m[0]
    draw.text((cx - w_m / 2, h * 0.72), text_main, font=font_main, fill=(16, 42, 67, 255)) # #102A43
    
    bbox_s = draw.textbbox((0, 0), text_sub, font=font_sub)
    w_s = bbox_s[2] - bbox_s[0]
    draw.text((cx - w_s / 2, h * 0.81), text_sub, font=font_sub, fill=(98, 125, 152, 255)) # #627D98
    
    final_img = img.resize((size, size), Image.Resampling.LANCZOS)
    return final_img

def create_splash_logo_dark(size=512, scale=4):
    # Dark mode version with white/light text
    w = size * scale
    h = size * scale
    
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    cx, cy = w / 2, h * 0.44
    
    ratio = 0.9
    teal_primary = (0, 191, 165, 255)
    cyan_accent = (0, 229, 255, 255)
    mint_light = (224, 242, 241, 255)
    
    leaf_w = int(w * 0.13 * ratio)
    leaf_h = int(h * 0.34 * ratio)
    leaf_cy = cy - int(h * 0.02 * ratio)
    
    def draw_petal(center_x, center_y, width, height, angle_deg, color):
        p_img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        p_draw = ImageDraw.Draw(p_img)
        top_y = center_y - height / 2
        bottom_y = center_y + height / 2
        points = []
        steps = 40
        for i in range(steps + 1):
            t = i / steps
            cur_y = bottom_y - t * height
            curve_x = center_x - (width / 2) * math.sin(t * math.pi)
            points.append((curve_x, cur_y))
        for i in range(steps + 1):
            t = i / steps
            cur_y = top_y + t * height
            curve_x = center_x + (width / 2) * math.sin(t * math.pi)
            points.append((curve_x, cur_y))
            
        p_draw.polygon(points, fill=color)
        if angle_deg != 0:
            p_img = p_img.rotate(angle_deg, center=(center_x, center_y), resample=Image.BICUBIC)
        return p_img

    p_left_outer = draw_petal(cx - int(w * 0.16 * ratio), cy + int(h * 0.04 * ratio), int(leaf_w * 0.9), int(leaf_h * 0.8), -52, teal_primary)
    p_right_outer = draw_petal(cx + int(w * 0.16 * ratio), cy + int(h * 0.04 * ratio), int(leaf_w * 0.9), int(leaf_h * 0.8), 52, teal_primary)
    p_left_mid = draw_petal(cx - int(w * 0.09 * ratio), cy + int(h * 0.01 * ratio), int(leaf_w * 0.95), int(leaf_h * 0.92), -26, cyan_accent)
    p_right_mid = draw_petal(cx + int(w * 0.09 * ratio), cy + int(h * 0.01 * ratio), int(leaf_w * 0.95), int(leaf_h * 0.92), 26, cyan_accent)
    p_center = draw_petal(cx, leaf_cy, int(leaf_w * 1.05), leaf_h, 0, mint_light)
    
    img = Image.alpha_composite(img, p_left_outer)
    img = Image.alpha_composite(img, p_right_outer)
    img = Image.alpha_composite(img, p_left_mid)
    img = Image.alpha_composite(img, p_right_mid)
    img = Image.alpha_composite(img, p_center)
    
    draw = ImageDraw.Draw(img)
    dot_r = int(w * 0.042 * ratio)
    dot_cy = cy + int(h * 0.17 * ratio)
    draw.ellipse([cx - dot_r, dot_cy - dot_r, cx + dot_r, dot_cy + dot_r], fill=(0, 229, 255, 255))
    
    arc_box = [cx - int(w * 0.28 * ratio), cy - int(h * 0.1 * ratio), cx + int(w * 0.28 * ratio), cy + int(h * 0.28 * ratio)]
    draw.arc(arc_box, start=30, end=150, fill=teal_primary, width=int(14 * scale * ratio))
    
    try:
        font_main = ImageFont.truetype("arialbd.ttf", int(38 * scale))
        font_sub = ImageFont.truetype("arial.ttf", int(18 * scale))
    except Exception:
        font_main = ImageFont.load_default()
        font_sub = ImageFont.load_default()
        
    text_main = "MIND DRIJI"
    text_sub = "Digital Wellness Companion"
    
    bbox_m = draw.textbbox((0, 0), text_main, font=font_main)
    w_m = bbox_m[2] - bbox_m[0]
    draw.text((cx - w_m / 2, h * 0.72), text_main, font=font_main, fill=(255, 255, 255, 255))
    
    bbox_s = draw.textbbox((0, 0), text_sub, font=font_sub)
    w_s = bbox_s[2] - bbox_s[0]
    draw.text((cx - w_s / 2, h * 0.81), text_sub, font=font_sub, fill=(186, 218, 245, 255))
    
    final_img = img.resize((size, size), Image.Resampling.LANCZOS)
    return final_img

if __name__ == '__main__':
    print("Generating app icon...")
    app_icon = create_smooth_icon(1024)
    app_icon.save("assets/icons/app_icon.png", "PNG")
    
    print("Generating foreground icon...")
    fg_icon = create_foreground_icon(1024)
    fg_icon.save("assets/icons/app_icon_foreground.png", "PNG")
    
    print("Generating splash logo...")
    splash_logo = create_splash_logo(512)
    splash_logo.save("assets/splash/splash_logo.png", "PNG")

    print("Generating dark splash logo...")
    splash_dark = create_splash_logo_dark(512)
    splash_dark.save("assets/splash/splash_logo_dark.png", "PNG")
    
    print("Assets generated successfully!")
