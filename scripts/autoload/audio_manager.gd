extends Node
 
const SFX_PATHS := {
	"laser_player": "res://assets/audio/sfx/laserSmall_000.ogg",
	"laser_enemy": "res://assets/audio/sfx/laserRetro_001.ogg",
	"laser_heavy": "res://assets/audio/sfx/laserLarge_001.ogg",
	"explosion": "res://assets/audio/sfx/explosionCrunch_000.ogg",
	"explosion_big": "res://assets/audio/sfx/lowFrequency_explosion_000.ogg",
	"hit": "res://assets/audio/sfx/impactMetal_000.ogg",
	"hit_player": "res://assets/audio/sfx/impactMetal_002.ogg",
	"ui_click": "res://assets/audio/sfx/computerNoise_001.ogg",
	"ui_confirm": "res://assets/audio/sfx/doorOpen_000.ogg",
	"goal": "res://assets/audio/sfx/forceField_001.ogg",
}

const MUSIC_PATHS := {
	"menu": "res://assets/audio/music/menu.ogg",
	"level": "res://assets/audio/music/level.ogg",
}

const POOL_SIZE := 12

var _streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _current_music := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for key in SFX_PATHS:
		_streams[key] = load(SFX_PATHS[key])
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_pool.append(player)
	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = -9.0
	# Loop the track by restarting it when it ends.
	_music_player.finished.connect(_music_player.play)
	add_child(_music_player)


func play_sfx(key: String, volume_db := 0.0, pitch := 1.0) -> void:
	if not _streams.has(key):
		return
	for player in _pool:
		if not player.playing:
			player.stream = _streams[key]
			player.volume_db = volume_db
			player.pitch_scale = pitch
			player.play()
			return


## Plays a sound at a position in the 3D world (volume falls with distance).
func play_sfx_3d(key: String, position: Vector3, volume_db := 0.0) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _streams.has(key):
		return
	var player := AudioStreamPlayer3D.new()
	player.stream = _streams[key]
	player.volume_db = volume_db
	player.unit_size = 30.0
	player.max_distance = 450.0
	player.finished.connect(player.queue_free)
	scene.add_child(player)
	player.global_position = position
	player.play()


func play_music(key: String) -> void:
	if key == _current_music and _music_player.playing:
		return
	_current_music = key
	_music_player.stream = load(MUSIC_PATHS[key])
	_music_player.play()
