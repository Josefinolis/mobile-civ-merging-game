# Merge Town

A mobile merge game where you combine buildings to create a thriving city. Built with Godot 4.

## Gameplay

- **Tap "BUILD NEW"** to spawn new buildings (costs energy)
- **Drag and drop** buildings onto matching buildings to merge them
- **Higher level buildings** generate more coins per second
- **Collect coins** to unlock new features (coming soon)

## Building Progression

| Level | Building | Coins/sec |
|-------|----------|-----------|
| 1 | Tent | 0.1 |
| 2 | Hut | 0.3 |
| 3 | Cabin | 0.8 |
| 4 | House | 2.0 |
| 5 | Villa | 5.0 |
| 6 | Mansion | 12.0 |
| 7 | Tower | 30.0 |
| 8 | Skyscraper | 75.0 |
| 9 | Monument | 200.0 |
| 10 | Wonder | 500.0 |

## Features

- Merge mechanics with 10 building tiers
- Passive coin generation
- Energy system with regeneration
- Auto-save on exit
- Offline earnings (50% efficiency, max 8 hours)
- Smooth animations and visual feedback

## Tech Stack

- **Engine**: Godot 4.2+
- **Language**: GDScript
- **Target**: Android (primary), iOS (future)

## Development

### Prerequisites

- [Godot 4.2+](https://godotengine.org/download)
- For Android export: Android SDK, JDK 17

### Running locally

1. Clone the repository
2. Open `project.godot` with Godot 4
3. Press F5 to run

### Building APK locally

1. Configure Android export template in Godot
2. Go to Project > Export
3. Select Android preset
4. Click "Export Project"

## Project Structure

```
mobile-civ-merging-game/
├── scenes/
│   ├── main.tscn          # Main game scene
│   └── building.tscn      # Building prefab
├── scripts/
│   ├── autoload/
│   │   ├── game_manager.gd  # Global game state
│   │   └── save_manager.gd  # Save/load system
│   ├── building.gd        # Building behavior
│   ├── game_grid.gd       # Grid management
│   └── ui_manager.gd      # UI handling
├── assets/
│   ├── sprites/
│   ├── audio/
│   └── fonts/
├── .github/
│   └── workflows/
│       └── release.yml    # CI/CD for APK builds
├── project.godot          # Godot project file
└── README.md
```

## Releases

APK builds are automatically generated via GitHub Actions when:
- A tag with format `v*` is pushed (e.g., `v1.0.0`)
- Manual workflow dispatch

Download the latest APK from the [Releases](../../releases) page.

## Roadmap

- [ ] Sound effects and music
- [ ] Achievement system
- [ ] Daily rewards
- [ ] Special events
- [ ] Premium buildings
- [ ] Ad integration (rewarded videos)
- [ ] In-app purchases
- [ ] Leaderboards
- [ ] iOS support

## License

MIT License - See [LICENSE](LICENSE) for details.
