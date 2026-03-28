# Required Assets

Place ALL these PNGs inside this directory (`assets/images/`).
Every file listed below is directly referenced in the code. Missing files = crash.

## Villagers (front-facing, standing upright, transparent background)

- [ ] `cat_villager.png` - kawaii cat character
- [ ] `dog_villager.png` - kawaii dog character
- [ ] `rabbit_villager.png` - kawaii rabbit character

### Sad Villagers (same characters but sad expression, used when happiness is low)

- [ ] `cat_villager_sad.png` - sad kawaii cat character
- [ ] `dog_villager_sad.png` - sad kawaii dog character
- [ ] `rabbit_villager_sad.png` - sad kawaii rabbit character

> The code moves them around the village, flips them left/right,
> and applies a bobbing bounce to simulate walking.
> You only need ONE static image per villager (not a sprite sheet).
> Sad variants are shown when village happiness drops below threshold.

## Buildings - Level 1 (transparent background)

- [ ] `house.png` - small cozy house
- [ ] `park.png` - small park with a tree
- [ ] `school.png` - small school building
- [ ] `hospital.png` - small clinic
- [ ] `water_plant.png` - small water tower
- [ ] `power_plant.png` - small power station

## Buildings - Level 2 (transparent background)

- [ ] `house_lv2.png` - medium house, more detailed
- [ ] `park_lv2.png` - medium park with more trees
- [ ] `school_lv2.png` - medium school, bigger
- [ ] `hospital_lv2.png` - medium hospital
- [ ] `water_plant_lv2.png` - medium water tower
- [ ] `power_plant_lv2.png` - medium power station

## Buildings - Level 3 (transparent background)

- [ ] `house_lv3.png` - large, grand house
- [ ] `park_lv3.png` - large park with fountain
- [ ] `school_lv3.png` - large school campus
- [ ] `hospital_lv3.png` - large hospital
- [ ] `water_plant_lv3.png` - large water plant complex
- [ ] `power_plant_lv3.png` - large power plant complex

## Buildings - Construction placeholder

- [ ] `building_construction.png` - generic "under construction" image (scaffolding, crane, etc.)

> This single image is shown for ANY building during construction.

## Resources (used in HUD, reward popups, cost displays, stats)

- [ ] `coin.png` - kawaii gold coin icon
- [ ] `gem.png` - kawaii purple gem icon
- [ ] `wood.png` - kawaii wood/log resource icon
- [ ] `metal.png` - kawaii metal ingot/bar resource icon

> These appear throughout the Flutter UI: resource bar, reward popup,
> building cost labels, and stats screen.

---

## Total: 31 files needed

| #   | Filename                    | Size suggestion | Transparent? |
| --- | --------------------------- | --------------- | ------------ |
| 1   | `building_construction.png` | 192x192px       | YES          |
| 2   | `house.png`                 | 192x192px       | YES          |
| 3   | `house_lv2.png`             | 192x192px       | YES          |
| 4   | `house_lv3.png`             | 192x192px       | YES          |
| 5   | `park.png`                  | 192x192px       | YES          |
| 6   | `park_lv2.png`              | 192x192px       | YES          |
| 7   | `park_lv3.png`              | 192x192px       | YES          |
| 8   | `school.png`                | 192x192px       | YES          |
| 9   | `school_lv2.png`            | 192x192px       | YES          |
| 10  | `school_lv3.png`            | 192x192px       | YES          |
| 11  | `hospital.png`              | 192x192px       | YES          |
| 12  | `hospital_lv2.png`          | 192x192px       | YES          |
| 13  | `hospital_lv3.png`          | 192x192px       | YES          |
| 14  | `water_plant.png`           | 192x192px       | YES          |
| 15  | `water_plant_lv2.png`       | 192x192px       | YES          |
| 16  | `water_plant_lv3.png`       | 192x192px       | YES          |
| 17  | `power_plant.png`           | 192x192px       | YES          |
| 18  | `power_plant_lv2.png`       | 192x192px       | YES          |
| 19  | `power_plant_lv3.png`       | 192x192px       | YES          |
| 20  | `cat_villager.png`          | 128x168px       | YES          |
| 21  | `dog_villager.png`          | 128x168px       | YES          |
| 22  | `rabbit_villager.png`       | 128x168px       | YES          |
| 23  | `cat_villager_sad.png`      | 128x168px       | YES          |
| 24  | `dog_villager_sad.png`      | 128x168px       | YES          |
| 25  | `rabbit_villager_sad.png`   | 128x168px       | YES          |
| 26  | `coin.png`                  | 64x64px         | YES          |
| 27  | `gem.png`                   | 64x64px         | YES          |
| 28  | `wood.png`                  | 64x64px         | YES          |
| 29  | `metal.png`                 | 64x64px         | YES          |
| 30  | `grass_tile.png`            | 192x192px       | YES          |
| 31  | `road_tile.png`             | 192x192px       | YES          |

## Art style reminder

- Kawaii / pastel color palette
- Soft colors, rounded shapes
- 2D top-down or front-facing style
- Simple, cute, minimal details
