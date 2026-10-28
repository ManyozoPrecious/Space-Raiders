# Space Raiders - COM415 assignment (Godot 4.7.2, GDScript, Android touch)

An EverSpace 2 style 3D space shooter. Shoot down the required number of enemies,
then fly into the glowing beacon to complete the level.

IMPORTANT: this project was written without being able to run Godot, so it has
never been executed. Expect to fix a few small errors on first run (see
"If something goes wrong" below). Send me the red error text from the Godot
Output panel and I will fix it.

## 1. First run on your PC (do this before Android)

1. Install Godot **4.7.2** (standard version, not .NET).
2. Godot Project Manager > Import > select this folder's `project.godot`.
3. The first open takes a few minutes: Godot imports all models and textures.
   Wait until the progress bar in the bottom right is finished.
4. Project > Project Settings > Plugins: tick **Enable** next to *FlightNavigation3D*
   (it may already be enabled).
5. Press **F5** to play.
   * Menu: PLAY, SELECT SHIP (3 ships, shows speed/acceleration), SELECT LEVEL (2 levels).
   * Mouse acts as touch. Drag the left joystick to steer, hold the FIRE button.
   * Keyboard testing: arrow keys steer, Space fires.

## 2. How to play

* Steer with the joystick (bottom-left), fire with the red button (bottom-right).
* Enemy icons (orange/red circles) follow enemies on screen and point to them at the
  screen edge; the distance is shown below each icon.
* Destroy the required enemies (counter at the top), then the cyan beacon activates.
  Fly into it to finish. Your time is shown, then you can REPLAY or go to the MAIN MENU.
* Health reaches 0 = GAME OVER: CONTINUE restarts the level, QUIT returns to the menu.
* Level 1 "Asteroid Belt" is in space (6 enemies). Level 2 "Canyon World" is on a planet
  surface (8 enemies).

## 3. Export to Android

1. Install **Android Studio** (it installs the Android SDK) and **OpenJDK 17**.
   In Android Studio > SDK Manager install: Android SDK Platform-Tools, Build-Tools 34.0.0,
   Platform 34, Command-line Tools, CMake 3.10.2, NDK r28b (versions Godot asks for in
   its export dialog).
2. In Godot: Editor > Editor Settings > Export > Android: set the *Android SDK Path*,
   *Java SDK Path* and create a *Debug Keystore* (Godot's docs, "Exporting for Android",
   show the keytool command).
3. Editor > Manage Export Templates > Download and Install (4.7.2).
4. Project > Install Android Build Template > Install (only needed if the export dialog asks).
5. Project > Export > Add... > Android. Tick *Use Gradle Build* only if you installed the
   build template. Set a unique package name, e.g. `com.yourname.spaceraiders`.
   Under Architectures tick **arm64-v8a**.
6. On the phone: enable Developer Options and USB debugging, plug it in. In Godot press the
   **Android icon (one-click deploy)** at the top right to build and run on the phone.
7. The game is landscape only (set in project settings).

## 4. Recording the required 3 minute video (real device, MP4)

1. Install **scrcpy** on your PC (github.com/Genymobile/scrcpy).
2. Phone plugged in with USB debugging, then run:
   `scrcpy --record gameplay.mp4`
3. Play for about 3 minutes and show everything the brief lists: main menu, ship select
   (speed/acceleration), level select, both levels, shooting, enemies attacking, health
   dropping, game over (continue AND quit), completing a level with the time screen,
   replay and main menu.
4. Close scrcpy to finish the MP4.

## 5. Where each assignment requirement lives

| Requirement | Where |
|---|---|
| Main menu with sub menus (start, ship select, level select) | `scripts/ui/main_menu.gd` |
| 3 ships with different speed/acceleration, shown on screen | `scripts/autoload/game_state.gd` (SHIPS), shown in `main_menu.gd` |
| Level complete shows time, replay or main menu | `scripts/ui/hud.gd` `show_complete()` |
| Game over, continue restarts, quit goes to menu | `hud.gd` `show_game_over()` |
| HUD health + touch hint images | `hud.gd`, `virtual_joystick.gd`, `touch_button.gd` |
| 2 levels (space and planet surface) | `scripts/levels/space_level.gd`, `planet_level.gd` |
| Virtual joystick steering, laser shooting | `virtual_joystick.gd`, `player_ship.gd`, `projectile.gd` |
| EverSpace style perspective camera | `scripts/player/chase_camera.gd` |
| 2 enemy types with icons | `scripts/enemy/enemy_ship.gd` (fighter, gunship), icons in `hud.gd` |
| Finite State Machine (Wander, Chase, Attack) | `scripts/core/state_machine.gd`, `scripts/enemy/*_state.gd` |
| 3+ steering behaviours | `scripts/core/steering.gd`: wander, seek/pursue, path following, obstacle avoidance |
| godot_flight_navigation_3d plugin | `level_base.gd` `_build_navigation()`, used by `enemy_ship.gd` `request_path()` |
| Particles and lighting | `scripts/core/vfx.gd`, lights in the level scripts |
| Sound effects and music | `scripts/autoload/audio_manager.gd` |
| Health attribute | `scripts/combat/health_component.gd` |

## 6. Notes and decisions

* The GDQuest steering framework in your resources is the Godot 3 version, which does not
  load in Godot 4. I wrote my own small steering library (`steering.gd`) using the same
  ideas (Reynolds' steering behaviours). If your lecturer wants the GDQuest classes used
  directly, tell me and I will port them.
* The flight navigation volume is built when the level starts (a short "PREPARING FLIGHT
  NAVIGATION" screen). If it fails or takes more than 25 seconds, enemies fall back to
  straight-line steering so the game still plays.
* Models are scaled automatically (`model_util.gd`) because the import sizes differ.

## 7. If something goes wrong

* **A ship flies backwards / the model faces the camera**: in `scripts/autoload/game_state.gd`
  change `"yaw_offset": 180.0` to `0.0` for that ship (enemy ships: `yaw_offset` in
  `scripts/enemy/enemy_ship.gd`).
* **Ships look too big/small**: change `"size"` in the same places.
* **Flight navigation errors or game freezes at "PREPARING..."**: in `level_base.gd` lower
  `NAV_LAYER_COUNT` from 5 to 4, or tell me the error.
* **Too hard / too easy**: enemy stats are in `enemy_ship.gd` (`TYPES`), kills needed are
  `kills_required` in each level script.
* **Slow on the phone**: set `shadow_enabled` false in `planet_level.gd`, and reduce the
  decor count (`for i in 90`) and asteroid count (`for i in 55`).
* **Parse errors on first run**: copy the red text from the Output panel to me.

## 8. Credits and references (also cited in code comments)

* Finite state machine pattern: GDQuest, https://www.gdquest.com/tutorial/godot/design-patterns/finite-state-machine/
* 3D shooting concept: KidsCanCode, https://kidscancode.org/godot_recipes/3.x/3d/3d_shooting/index.html
* Steering behaviours: Craig Reynolds, "Steering Behaviors For Autonomous Characters" (1999)
* godot_flight_navigation_3d by RevolNoom (MIT licence, included in `addons/` and `src/`)
* Art and audio: Quaternius (ships, environment, CC0), Kenney (UI, mobile controls,
  crosshairs, sci-fi sounds, CC0), Florian Stracker (music). Licence files are next to the
  assets in `assets/`. Check the licence text before submitting.
