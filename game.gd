extends Node2D

# ============================================================================
# BLOCK SHIFT — v1.5.1 (UI fix + new skins)
# ============================================================================

const GAME_VERSION = "1.5.1"
const REF_SIZE = Vector2(900, 1600)
const GRID_SIZE = 8
const GRID_MARGIN_X = 45.0
const CELL_SIZE_BASE = (900.0 - GRID_MARGIN_X * 2.0) / GRID_SIZE
const GRID_POS_BASE = Vector2(GRID_MARGIN_X + 30.0, 310.0)
const TOUCH_Y_OFFSET_BASE = 90.0
const TRAY_BLOCK_STEP = 54.0
const TRAY_BLOCK_SIZE = 48.0
const MAX_TRAY_SIZE = 220.0
const TRAY_SLOT_CENTERS = [Vector2(170, 1240), Vector2(450, 1240), Vector2(730, 1240)]

const SAVE_PATH = "user://highscore.save"
const TIME_SAVE_PATH = "user://time_high.save"
const GAME_SAVE_PATH = "user://game_state.save"
const SETTINGS_SAVE_PATH = "user://settings.save"
const DAILY_SAVE_PATH = "user://daily.save"
const SKIN_SAVE_PATH = "user://skin.save"
const PROGRESS_SAVE_PATH = "user://progress.save"
const TUTORIAL_SAVE = "user://tutorial.done"
const TIME_TUTORIAL_SAVE = "user://time_tutorial.done"

const POP_DURATION = 0.18
const FLASH_DURATION = 0.3
const COMBO_POPUP_DURATION = 0.9
const DAILY_BONUS_SCORE = 500
const TIME_DURATION = 60.0
const TIME_PER_LINE = 2.0
const LOADING_MIN_TIME = 2.4
const COMBO_GRACE = 3

const TOUCH_DRAG_THRESHOLD = 8.0
const FPS_HIGH = 60
const FPS_LOW = 30

const DENSITY_RESCUE = 0.55
const DENSITY_EMERGENCY = 0.85
const DENSITY_WARN = 0.80
const PIECE_SPAWN_STAGGER = 0.10

const REVIVE_TIMER = 5.0
const REVIVE_DELAY = 1.5
const REVIVE_APPEAR_DUR = 0.35
const REVIVE_DIM_DUR = 0.5
const REVIVE_URGENT_AT = 2.0

const C_BG_TOP    = Color("#1a0530")
const C_BG_MID    = Color("#0e0224")
const C_BG_BOT    = Color("#04000d")
const C_PANEL     = Color("#1a0a3a")
const C_PANEL_2   = Color("#250e52")
const C_BORDER    = Color("#6a3aee")
const C_BORDER_HI = Color("#a07aff")

const N_CYAN      = Color("#2EC4FF")
const N_CYAN_SH   = Color("#0f5fa8")
const N_MAGENTA   = Color("#FF2FD0")
const N_MAGENTA_SH= Color("#a01878")
const N_GREEN     = Color("#9BFF3D")
const N_GREEN_SH  = Color("#3a8a10")
const N_BLUE      = Color("#3a68ff")
const N_BLUE_SH   = Color("#1a3ab0")
const N_PURPLE    = Color("#B15CFF")
const N_PURPLE_SH = Color("#5a1aa0")
const N_ORANGE    = Color("#FF9E2C")
const N_ORANGE_SH = Color("#a05000")
const N_PINK      = Color("#FF5C7C")
const N_YELLOW    = Color("#FFD53A")
const N_RED       = Color("#FF3344")

# === SHIFT MODE ===
const SHIFT_LINES_STEP    = 3
const SHIFT_WARN_DURATION = 0.7
const SHIFT_MAX_DIR       = 4
const SHIFT_WRAP          = true

# === CAMPAIGN MAP ===
const CAMP_TOTAL_LEVELS = 999
const CAMP_PAGE_SIZE = 30
const CAMP_COLS = 3
const CAMP_ROWS = 10
const CAMP_CELL_W = 240.0
const CAMP_CELL_H = 80.0
const CAMP_CELL_GAP = 20.0
const CAMP_START_Y = 360.0

# === UI input protection ===
const UI_ACTION_COOLDOWN = 0.18

enum State { LOADING, TUTORIAL, MENU, MODE_SELECT, SKINS, ACHIEVEMENTS, SETTINGS, CAMPAIGN_MAP, PLAYING, PAUSED, GAME_OVER, REVIVE }
enum GameMode { CLASSIC, TIME, CAMPAIGN }
enum Quality { LOW, MEDIUM, HIGH }

var state = State.LOADING
var settings_return_state = State.MENU
var has_saved_game = false
var tutorial_step: int = 0
var tutorial_for_mode: int = 0
var reduce_effects: bool = false
var loading_progress: float = 0.0
var loading_elapsed: float = 0.0
var loading_ready: bool = false
var game_mode: int = GameMode.CLASSIC
var time_left: float = 0.0
var time_high: int = 0
var campaign_level: int = 1
var campaign_max_unlocked: int = 1
var campaign_moves_left: int = 0
var campaign_moves_total: int = 0
var campaign_won: bool = false
var lvl_crystals: int = 0
var lvl_diamonds: int = 0
var lvl_stars: int = 0
var goal_crystals: int = 0
var goal_diamonds: int = 0
var goal_stars: int = 0
var level_stars_earned: int = 0
var level_stars_saved: Dictionary = {}
var ui_scale = 1.0
var layout_offset = Vector2.ZERO
var cell_size = CELL_SIZE_BASE
var grid_pos = GRID_POS_BASE
var grid = []
var score = 0
var high_score = 0
var combo_count = 0
var combo_streak = 0
var combo_grace_turns: int = 0
var screen_shake = 0.0
var _shake_offset := Vector2.ZERO
var _drag_trail_timer := 0.0
var _go_scatter_timer := 0.0
var _menu_enter_t: float = 0.0
var _last_ui_action_time: float = 0.0

var _bg_cache: ImageTexture = null
var _bg_cache_size: Vector2i = Vector2i.ZERO

var score_popups: Array = []
var row_glow_cells: Array = []
var hint_result: Dictionary = {}
var hint_timer: float = 0.0
var hint_visible: bool = false
var hint_btn_rect: Rect2 = Rect2(0, 0, 0, 0)
const HINT_IDLE_TIME = 12.0
const HINT_SHOW_DURATION = 3.0

var field_density: float = 0.0
var _density_pulse: float = 0.0

var _last_piece_shapes: Array = []
var _last_piece_colors: Array = []
var _pieces_since_bomb: int = 0
var _pieces_since_line: int = 0
var _piece_spawn_delay: Array = [0.0, 0.0, 0.0]

# SHIFT state
var cleared_lines_total: int = 0
var shift_lines_required: int = SHIFT_LINES_STEP
var shift_direction: int = 0
var shift_in_progress: bool = false
var shift_warning_count: int = 0
var shift_warning_timer: float = 0.0
var _shift_pending_gameover: bool = false

var revive_timer: float = 0.0
var revive_active: bool = false
var revive_from_mode: int = GameMode.CLASSIC
var revive_delay_timer: float = 0.0
var revive_appear: float = 0.0
var revive_dim: float = 0.0
var revive_shown: bool = false
var revive_last_tick_sec: int = -1

var _safe_insets := Vector4.ZERO
var _touch_press_pos: Vector2 = Vector2.ZERO
var _touch_started_drag: bool = false
var _active_touch_index: int = -1
var _touch_time: float = 0.0

var COLOR_PALETTE = [
	Color("#2EC4FF"), Color("#9BFF3D"), Color("#FF2FD0"),
	Color("#FF9E2C"), Color("#B15CFF"), Color("#FF5C7C"), Color("#2EE6D6"),
]

const SKINS = [
	{"id": "neon",    "name": "Неон",     "name_en": "Neon",    "corner": 0.28, "style": "neon",
	 "hl_size": Vector2(0.85, 0.42), "hl_alpha": 0.85},
	{"id": "glow",    "name": "Свечение", "name_en": "Glow",    "corner": 0.32, "style": "glow",
	 "hl_size": Vector2(0.80, 0.38), "hl_alpha": 0.75},
	{"id": "soft",    "name": "Мягкие",   "name_en": "Soft",    "corner": 0.48, "style": "soft",
	 "hl_size": Vector2(0.70, 0.32), "hl_alpha": 0.55},
	{"id": "outline", "name": "Контур",   "name_en": "Outline", "corner": 0.24, "style": "outline",
	 "hl_size": Vector2(0.0, 0.0),   "hl_alpha": 0.0},
]

var current_skin_id = "neon"

func _current_skin() -> Dictionary:
	for s in SKINS:
		if s.id == current_skin_id: return s
	return SKINS[0]

func _skin_name(skin: Dictionary) -> String:
	if current_lang == "ru": return skin.get("name", skin.id)
	return skin.get("name_en", skin.get("name", skin.id))

const ACHIEVEMENTS = [
	{"id": "ln1", "g": 1, "c": "lines"}, {"id": "ln5", "g": 5, "c": "lines"},
	{"id": "ln10", "g": 10, "c": "lines"}, {"id": "ln25", "g": 25, "c": "lines"},
	{"id": "ln50", "g": 50, "c": "lines"}, {"id": "ln100", "g": 100, "c": "lines"},
	{"id": "ln250", "g": 250, "c": "lines"}, {"id": "ln500", "g": 500, "c": "lines"},
	{"id": "ln1000", "g": 1000, "c": "lines"}, {"id": "ln5000", "g": 5000, "c": "lines"},
	{"id": "sc500", "g": 500, "c": "score"}, {"id": "sc1000", "g": 1000, "c": "score"},
	{"id": "sc2500", "g": 2500, "c": "score"}, {"id": "sc5000", "g": 5000, "c": "score"},
	{"id": "sc10000", "g": 10000, "c": "score"}, {"id": "sc25000", "g": 25000, "c": "score"},
	{"id": "sc50000", "g": 50000, "c": "score"}, {"id": "sc100000", "g": 100000, "c": "score"},
	{"id": "sc250000", "g": 250000, "c": "score"}, {"id": "sc500000", "g": 500000, "c": "score"},
	{"id": "tm300", "g": 300, "c": "time"}, {"id": "tm500", "g": 500, "c": "time"},
	{"id": "tm1000", "g": 1000, "c": "time"}, {"id": "tm1500", "g": 1500, "c": "time"},
	{"id": "tm2000", "g": 2000, "c": "time"}, {"id": "tm3000", "g": 3000, "c": "time"},
	{"id": "tm5000", "g": 5000, "c": "time"}, {"id": "tm10000", "g": 10000, "c": "time"},
	{"id": "cb2", "g": 2, "c": "combo"}, {"id": "cb3", "g": 3, "c": "combo"},
	{"id": "cb4", "g": 4, "c": "combo"}, {"id": "cb5", "g": 5, "c": "combo"},
	{"id": "cb7", "g": 7, "c": "combo"}, {"id": "cb10", "g": 10, "c": "combo"},
	{"id": "cb15", "g": 15, "c": "combo"}, {"id": "cb20", "g": 20, "c": "combo"},
	{"id": "bm1", "g": 1, "c": "bomb"}, {"id": "bm5", "g": 5, "c": "bomb"},
	{"id": "bm10", "g": 10, "c": "bomb"}, {"id": "bm25", "g": 25, "c": "bomb"},
	{"id": "bm50", "g": 50, "c": "bomb"}, {"id": "bm100", "g": 100, "c": "bomb"},
	{"id": "gm1", "g": 1, "c": "games"}, {"id": "gm5", "g": 5, "c": "games"},
	{"id": "gm10", "g": 10, "c": "games"}, {"id": "gm25", "g": 25, "c": "games"},
	{"id": "gm50", "g": 50, "c": "games"}, {"id": "gm100", "g": 100, "c": "games"},
	{"id": "gm250", "g": 250, "c": "games"}, {"id": "gm500", "g": 500, "c": "games"},
	{"id": "cp1", "g": 1, "c": "camp"}, {"id": "cp5", "g": 5, "c": "camp"},
	{"id": "cp10", "g": 10, "c": "camp"}, {"id": "cp25", "g": 25, "c": "camp"},
	{"id": "cp50", "g": 50, "c": "camp"}, {"id": "cp100", "g": 100, "c": "camp"},
	{"id": "cp200", "g": 200, "c": "camp"}, {"id": "cp333", "g": 333, "c": "camp"},
	{"id": "cp500", "g": 500, "c": "camp"}, {"id": "cp999", "g": 999, "c": "camp"},
	{"id": "sp1", "g": 1, "c": "sp"}, {"id": "sp2", "g": 1, "c": "sp"},
	{"id": "sp3", "g": 1, "c": "sp"}, {"id": "sp4", "g": 1, "c": "sp"},
	{"id": "sp5", "g": 1, "c": "sp"}, {"id": "sp6", "g": 10, "c": "sp"},
	{"id": "sp7", "g": 7, "c": "sp"}, {"id": "sp8", "g": 4, "c": "sp"},
	{"id": "sp9", "g": 1, "c": "sp"}, {"id": "sp10", "g": 1, "c": "sp"},
]

const ACH_T = {
	"ru": {"lines": ["%d линий", "Собери %d линий"], "score": ["%d очков", "Набери %d очков"],
		"combo": ["Комбо x%d", "Комбо x%d"], "bomb": ["%d бомб", "Используй %d бомб"],
		"games": ["%d игр", "Сыграй %d игр"], "camp": ["Уровень %d", "Пройди %d уровней"],
		"time": ["%d очков", "Набери %d очков на время"]},
	"en": {"lines": ["%d lines", "Collect %d lines"], "score": ["%d points", "Earn %d points"],
		"combo": ["Combo x%d", "Make combo x%d"], "bomb": ["%d bombs", "Use %d bombs"],
		"games": ["%d games", "Play %d games"], "camp": ["Level %d", "Complete %d levels"],
		"time": ["%d points", "Earn %d points in Time"]},
	"es": {"lines": ["%d líneas", "Consigue %d líneas"], "score": ["%d puntos", "Gana %d puntos"],
		"combo": ["Combo x%d", "Haz combo x%d"], "bomb": ["%d bombas", "Usa %d bombas"],
		"games": ["%d juegos", "Juega %d partidas"], "camp": ["Nivel %d", "Completa %d niveles"],
		"time": ["%d puntos", "Gana %d puntos"]},
	"de": {"lines": ["%d Linien", "Sammle %d Linien"], "score": ["%d Punkte", "Erreiche %d Punkte"],
		"combo": ["Combo x%d", "Schaffe Combo x%d"], "bomb": ["%d Bomben", "Benutze %d Bomben"],
		"games": ["%d Spiele", "Spiele %d Spiele"], "camp": ["Level %d", "Schaffe %d Level"],
		"time": ["%d Punkte", "Erreiche %d Punkte"]},
	"fr": {"lines": ["%d lignes", "Collecte %d lignes"], "score": ["%d points", "Gagne %d points"],
		"combo": ["Combo x%d", "Fais combo x%d"], "bomb": ["%d bombes", "Utilise %d bombes"],
		"games": ["%d parties", "Joue %d parties"], "camp": ["Niveau %d", "Termine %d niveaux"],
		"time": ["%d points", "Gagne %d points"]},
	"pt": {"lines": ["%d linhas", "Junte %d linhas"], "score": ["%d pontos", "Ganhe %d pontos"],
		"combo": ["Combo x%d", "Faça combo x%d"], "bomb": ["%d bombas", "Use %d bombas"],
		"games": ["%d jogos", "Jogue %d partidas"], "camp": ["Nível %d", "Complete %d níveis"],
		"time": ["%d pontos", "Ganhe %d pontos"]},
	"it": {"lines": ["%d linee", "Raccogli %d linee"], "score": ["%d punti", "Guadagna %d punti"],
		"combo": ["Combo x%d", "Fai combo x%d"], "bomb": ["%d bombe", "Usa %d bombe"],
		"games": ["%d partite", "Gioca %d partite"], "camp": ["Livello %d", "Completa %d livelli"],
		"time": ["%d punti", "Guadagna %d punti"]},
	"tr": {"lines": ["%d satır", "Toplam %d satır"], "score": ["%d puan", "%d puan kazan"],
		"combo": ["Kombo x%d", "Kombo x%d yap"], "bomb": ["%d bomba", "%d bomba kullan"],
		"games": ["%d oyun", "%d oyun oyna"], "camp": ["Seviye %d", "%d seviye tamamla"],
		"time": ["%d puan", "Zamanda %d puan"]},
}

const ACH_SP = {
	"ru": {"sp1": ["Первый шаг", "Поставь первую фигуру"], "sp2": ["Трипл-удар", "3 линии одним ходом"],
		"sp3": ["Пента-удар", "5+ линий одним ходом"], "sp4": ["Идеально!", "Очисти всю доску"],
		"sp5": ["Камбэк", "Линия на последнем ходу"], "sp6": ["Серия x10", "10 комбо подряд"],
		"sp7": ["Неделя", "Заходи 7 дней подряд"], "sp8": ["Коллекционер", "Попробуй все скины"],
		"sp9": ["Полуночник", "Играй после полуночи"], "sp10": ["Ранняя пташка", "Играй до 6 утра"]},
	"en": {"sp1": ["First step", "Place first piece"], "sp2": ["Triple hit", "3 lines in one move"],
		"sp3": ["Penta hit", "5+ lines in one move"], "sp4": ["Perfect!", "Clear the whole board"],
		"sp5": ["Comeback", "Line on the last move"], "sp6": ["Streak x10", "10 combo in a row"],
		"sp7": ["Week streak", "Log in 7 days in a row"], "sp8": ["Collector", "Try all skins"],
		"sp9": ["Night owl", "Play after midnight"], "sp10": ["Early bird", "Play before 6 AM"]},
	"es": {"sp1": ["Primer paso", "Primera pieza"], "sp2": ["Triple golpe", "3 líneas"],
		"sp3": ["Penta golpe", "5+ líneas"], "sp4": ["¡Perfecto!", "Limpia el tablero"],
		"sp5": ["Remontada", "Línea al último"], "sp6": ["Racha x10", "10 combos seguidos"],
		"sp7": ["Semana", "7 días seguidos"], "sp8": ["Coleccionista", "Todos los estilos"],
		"sp9": ["Noctámbulo", "Después de medianoche"], "sp10": ["Madrugador", "Antes de las 6"]},
	"de": {"sp1": ["Erster Schritt", "Erstes Teil"], "sp2": ["Dreifach", "3 Linien"],
		"sp3": ["Fünffach", "5+ Linien"], "sp4": ["Perfekt!", "Räume das Feld"],
		"sp5": ["Comeback", "Linie im letzten Zug"], "sp6": ["Serie x10", "10 Combos"],
		"sp7": ["Woche", "7 Tage in Folge"], "sp8": ["Sammler", "Alle Skins"],
		"sp9": ["Nachteule", "Nach Mitternacht"], "sp10": ["Früher Vogel", "Vor 6 Uhr"]},
	"fr": {"sp1": ["Premier pas", "Première pièce"], "sp2": ["Triple coup", "3 lignes"],
		"sp3": ["Penta coup", "5+ lignes"], "sp4": ["Parfait!", "Vide le plateau"],
		"sp5": ["Retour", "Ligne au dernier"], "sp6": ["Série x10", "10 combos"],
		"sp7": ["Semaine", "7 jours de suite"], "sp8": ["Collectionneur", "Tous les styles"],
		"sp9": ["Noctambule", "Après minuit"], "sp10": ["Lève-tôt", "Avant 6h"]},
	"pt": {"sp1": ["Primeiro passo", "Primeira peça"], "sp2": ["Golpe triplo", "3 linhas"],
		"sp3": ["Golpe penta", "5+ linhas"], "sp4": ["Perfeito!", "Limpe o tabuleiro"],
		"sp5": ["Virada", "Linha no último"], "sp6": ["Sequência x10", "10 combos"],
		"sp7": ["Semana", "7 dias seguidos"], "sp8": ["Colecionador", "Todos os estilos"],
		"sp9": ["Coruja", "Depois da meia-noite"], "sp10": ["Madrugador", "Antes das 6h"]},
	"it": {"sp1": ["Primo passo", "Primo pezzo"], "sp2": ["Triplo colpo", "3 linee"],
		"sp3": ["Penta colpo", "5+ linee"], "sp4": ["Perfetto!", "Svuota il campo"],
		"sp5": ["Rimonta", "Linea all'ultima"], "sp6": ["Serie x10", "10 combo"],
		"sp7": ["Settimana", "7 giorni di fila"], "sp8": ["Collezionista", "Tutti gli stili"],
		"sp9": ["Nottambulo", "Dopo mezzanotte"], "sp10": ["Mattiniero", "Prima delle 6"]},
	"tr": {"sp1": ["İlk adım", "İlk parça"], "sp2": ["Üçlü vuruş", "3 satır"],
		"sp3": ["Beşli vuruş", "5+ satır"], "sp4": ["Mükemmel!", "Tüm tahtayı temizle"],
		"sp5": ["Geri dönüş", "Son hamlede satır"], "sp6": ["Seri x10", "10 kombo"],
		"sp7": ["Hafta", "7 gün üst üste"], "sp8": ["Koleksiyoncu", "Tüm stiller"],
		"sp9": ["Gece kuşu", "Gece yarısından sonra"], "sp10": ["Erken kuş", "Sabah 6'dan önce"]},
}

var ach_unlocked: Dictionary = {}
var _ach_dirty := false

var stats = {
	"total_lines": 0, "total_bombs": 0, "games_played": 0,
	"best_score": 0, "best_time": 0, "campaign_max": 1,
	"daily_streak": 0, "skins_used": {}, "combo_max": 0,
	"triple_clear": 0, "five_clear": 0, "perfect_clear": 0,
	"comeback": 0, "streak10": 0, "play_first": 0,
	"night_owl": 0, "early_bird": 0
}

func _is_unlocked(id: String) -> bool: return ach_unlocked.get(id, false)

func _unlock(id: String):
	if _is_unlocked(id): return
	ach_unlocked[id] = true
	_ach_dirty = true
	play_sfx(sfx_combo, 1.6)
	trigger_flash(0.25)
	spawn_combo_popup(tr_("award_new") + ": " + _ach_name(id))

func _ach_name(id: String) -> String:
	var a = null
	for x in ACHIEVEMENTS:
		if x.id == id: a = x; break
	if a == null: return id
	var lang = current_lang if ACH_T.has(current_lang) else "en"
	var templ = ACH_T[lang]
	match a.c:
		"lines": return templ["lines"][0] % a.g
		"score": return templ["score"][0] % a.g
		"combo": return templ["combo"][0] % a.g
		"bomb": return templ["bomb"][0] % a.g
		"games": return templ["games"][0] % a.g
		"camp": return templ["camp"][0] % a.g
		"time": return templ["time"][0] % a.g
		"sp":
			var sp = ACH_SP[lang] if ACH_SP.has(lang) else ACH_SP["en"]
			return sp.get(id, [id, id])[0]
	return id

func _ach_desc(id: String) -> String:
	var a = null
	for x in ACHIEVEMENTS:
		if x.id == id: a = x; break
	if a == null: return ""
	var lang = current_lang if ACH_T.has(current_lang) else "en"
	var templ = ACH_T[lang]
	match a.c:
		"lines": return templ["lines"][1] % a.g
		"score": return templ["score"][1] % a.g
		"combo": return templ["combo"][1] % a.g
		"bomb": return templ["bomb"][1] % a.g
		"games": return templ["games"][1] % a.g
		"camp": return templ["camp"][1] % a.g
		"time": return templ["time"][1] % a.g
		"sp":
			var sp = ACH_SP[lang] if ACH_SP.has(lang) else ACH_SP["en"]
			return sp.get(id, [id, id])[1]
	return ""

func _ach_progress(id: String) -> int:
	var a = null
	for x in ACHIEVEMENTS:
		if x.id == id: a = x; break
	if a == null: return 0
	match a.c:
		"lines": return stats.total_lines
		"score": return stats.best_score
		"time": return stats.best_time
		"combo": return stats.combo_max
		"bomb": return stats.total_bombs
		"games": return stats.games_played
		"camp": return stats.campaign_max - 1
		"sp":
			match id:
				"sp1": return stats.play_first
				"sp2": return stats.triple_clear
				"sp3": return stats.five_clear
				"sp4": return stats.perfect_clear
				"sp5": return stats.comeback
				"sp6": return stats.streak10
				"sp7": return stats.daily_streak
				"sp8": return stats.skins_used.size()
				"sp9": return stats.night_owl
				"sp10": return stats.early_bird
	return 0

func check_achievements():
	for a in ACHIEVEMENTS:
		if not _is_unlocked(a.id) and _ach_progress(a.id) >= a.g: _unlock(a.id)
	if _ach_dirty:
		save_progress()
		_ach_dirty = false

func _check_time_of_day():
	var hour = int(Time.get_time_dict_from_system().get("hour", 12))
	if hour >= 0 and hour < 4: stats.night_owl = 1
	if hour >= 4 and hour < 6: stats.early_bird = 1

var quality: int = Quality.HIGH

func _detect_quality():
	if not OS.has_feature("mobile"):
		quality = Quality.HIGH; return
	var cpus = OS.get_processor_count()
	var screen = DisplayServer.screen_get_size()
	var pixels = screen.x * screen.y
	if cpus <= 4 or pixels < 1500000: quality = Quality.LOW
	elif cpus <= 6 or pixels < 3000000: quality = Quality.MEDIUM
	else: quality = Quality.HIGH
	if quality == Quality.LOW and not reduce_effects: reduce_effects = true

func _particle_count() -> int:
	if reduce_effects: return 0
	match quality:
		Quality.LOW: return 0
		Quality.MEDIUM: return 12
		_: return 30

func _burst_count(base: int) -> int:
	if reduce_effects: return 1
	match quality:
		Quality.LOW: return 1
		Quality.MEDIUM: return max(2, int(base / 3.0))
		_: return base

func trigger_shake(amount: float):
	if reduce_effects: return
	screen_shake = max(screen_shake, amount)

func _update_shake(delta):
	if reduce_effects:
		_shake_offset = Vector2.ZERO; screen_shake = 0.0; return
	if screen_shake > 0.0:
		screen_shake = max(0.0, screen_shake - delta * 28.0)
		if quality == Quality.LOW: _shake_offset = Vector2.ZERO
		else: _shake_offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * screen_shake * ui_scale
	else: _shake_offset = Vector2.ZERO

func get_shaked_grid_pos() -> Vector2: return grid_pos + _shake_offset

func _recalc_density():
	var filled = 0
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if grid[y][x] != null: filled += 1
	field_density = float(filled) / float(GRID_SIZE * GRID_SIZE)

# ============================================================================
# ICONS
# ============================================================================

func _draw_icon_star(c: Vector2, s: float, col: Color):
	var pts = PackedVector2Array()
	for i in range(10):
		var r = s if i % 2 == 0 else s * 0.45
		var a = -PI / 2.0 + i * PI / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, col)

func _draw_icon_play(c: Vector2, s: float, col: Color):
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-s * 0.45, -s * 0.65), c + Vector2(s * 0.65, 0), c + Vector2(-s * 0.45, s * 0.65)]), col)

func _draw_icon_gear(c: Vector2, s: float, col: Color):
	for i in range(8):
		var a = i * TAU / 8.0
		draw_colored_polygon(PackedVector2Array([
			c + Vector2(cos(a - 0.20), sin(a - 0.20)) * s * 0.95,
			c + Vector2(cos(a + 0.20), sin(a + 0.20)) * s * 0.95,
			c + Vector2(cos(a + 0.20), sin(a + 0.20)) * s * 0.60,
			c + Vector2(cos(a - 0.20), sin(a - 0.20)) * s * 0.60]), col)
	draw_circle(c, s * 0.62, col)
	draw_circle(c, s * 0.22, C_PANEL)

func _draw_icon_trophy(c: Vector2, s: float, col: Color):
	var cw = s * 0.85; var ch = s * 0.9; var top = c.y - s * 0.55
	draw_colored_polygon(PackedVector2Array([
		Vector2(c.x - cw * 0.5, top), Vector2(c.x + cw * 0.5, top),
		Vector2(c.x + cw * 0.32, top + ch * 0.72), Vector2(c.x - cw * 0.32, top + ch * 0.72)]), col)
	draw_arc(Vector2(c.x - cw * 0.5, top + ch * 0.28), s * 0.30, PI * 0.5, PI * 1.5, 12, col, sw(3))
	draw_arc(Vector2(c.x + cw * 0.5, top + ch * 0.28), s * 0.30, -PI * 0.5, PI * 0.5, 12, col, sw(3))
	draw_rect(Rect2(c.x - s * 0.18, c.y + s * 0.15, s * 0.36, s * 0.38), col)
	draw_rect(Rect2(c.x - s * 0.55, c.y + s * 0.53, s * 1.10, s * 0.20), col)

func _draw_icon_flame(c: Vector2, s: float, col: Color):
	draw_colored_polygon(PackedVector2Array([
		Vector2(c.x, c.y - s * 0.95), Vector2(c.x + s * 0.55, c.y - s * 0.10),
		Vector2(c.x + s * 0.40, c.y + s * 0.55), Vector2(c.x, c.y + s * 0.85),
		Vector2(c.x - s * 0.40, c.y + s * 0.55), Vector2(c.x - s * 0.55, c.y - s * 0.10)]), col)
	draw_colored_polygon(PackedVector2Array([
		Vector2(c.x, c.y - s * 0.30), Vector2(c.x + s * 0.22, c.y + s * 0.15),
		Vector2(c.x, c.y + s * 0.50), Vector2(c.x - s * 0.22, c.y + s * 0.15)]), Color(1, 1, 1, 0.7))

func _draw_icon_clock(c: Vector2, s: float, col: Color):
	draw_arc(c, s * 0.90, 0, TAU, 32, col, sw(3))
	draw_line(c, c + Vector2(0, -s * 0.55), col, sw(3))
	draw_line(c, c + Vector2(s * 0.40, 0), col, sw(3))

func _draw_icon_crown(c: Vector2, s: float, col: Color):
	draw_colored_polygon(PackedVector2Array([
		Vector2(c.x - s * 0.90, c.y + s * 0.40), Vector2(c.x - s * 0.90, c.y - s * 0.30),
		Vector2(c.x - s * 0.45, c.y + s * 0.05), Vector2(c.x, c.y - s * 0.55),
		Vector2(c.x + s * 0.45, c.y + s * 0.05), Vector2(c.x + s * 0.90, c.y - s * 0.30),
		Vector2(c.x + s * 0.90, c.y + s * 0.40)]), col)

func _draw_icon_home(c: Vector2, s: float, col: Color):
	draw_colored_polygon(PackedVector2Array([
		Vector2(c.x - s * 0.90, c.y - s * 0.05), Vector2(c.x, c.y - s * 0.85),
		Vector2(c.x + s * 0.90, c.y - s * 0.05)]), col)
	draw_rect(Rect2(c.x - s * 0.62, c.y - s * 0.05, s * 1.24, s * 0.85), col)
	draw_rect(Rect2(c.x - s * 0.20, c.y + s * 0.30, s * 0.40, s * 0.50), C_PANEL)

func _draw_icon_restart(c: Vector2, s: float, col: Color):
	draw_arc(c, s * 0.75, -PI * 0.35, PI * 1.35, 24, col, sw(4))
	var tip = c + Vector2(cos(PI * 1.35), sin(PI * 1.35)) * s * 0.75
	draw_colored_polygon(PackedVector2Array([
		tip + Vector2(-s * 0.30, -s * 0.05), tip + Vector2(s * 0.05, -s * 0.32), tip]), col)

func _draw_icon_check(c: Vector2, s: float, col: Color):
	draw_line(c + Vector2(-s * 0.60, 0), c + Vector2(-s * 0.10, s * 0.45), col, sw(5))
	draw_line(c + Vector2(-s * 0.10, s * 0.45), c + Vector2(s * 0.65, -s * 0.45), col, sw(5))

func _draw_icon_pause(c: Vector2, s: float, col: Color):
	draw_rect(Rect2(c.x - s * 0.55, c.y - s * 0.75, s * 0.35, s * 1.5), col)
	draw_rect(Rect2(c.x + s * 0.20, c.y - s * 0.75, s * 0.35, s * 1.5), col)

func _draw_icon_chevron(c: Vector2, s: float, col: Color, flip: bool = false):
	var dir = -1.0 if flip else 1.0
	draw_line(c + Vector2(-s * 0.3 * dir, -s * 0.6), c + Vector2(s * 0.3 * dir, 0), col, sw(4))
	draw_line(c + Vector2(s * 0.3 * dir, 0), c + Vector2(-s * 0.3 * dir, s * 0.6), col, sw(4))

func _draw_icon_speaker(c: Vector2, s: float, col: Color, waves: bool):
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-s * 0.8, -s * 0.4), c + Vector2(-s * 0.3, -s * 0.4),
		c + Vector2(s * 0.2, -s * 0.9), c + Vector2(s * 0.2, s * 0.9),
		c + Vector2(-s * 0.3, s * 0.4), c + Vector2(-s * 0.8, s * 0.4)]), col)
	if waves:
		draw_arc(c + Vector2(s * 0.5, 0), s * 0.55, -PI * 0.4, PI * 0.4, 10, col, sw(3))
		draw_arc(c + Vector2(s * 0.5, 0), s * 0.85, -PI * 0.4, PI * 0.4, 10, col, sw(3))

func _draw_icon_music(c: Vector2, s: float, col: Color):
	draw_circle(c + Vector2(-s * 0.4, s * 0.5), s * 0.35, col)
	draw_line(c + Vector2(-s * 0.05, s * 0.5), c + Vector2(-s * 0.05, -s * 0.7), col, sw(4))
	draw_line(c + Vector2(-s * 0.05, -s * 0.7), c + Vector2(s * 0.6, -s * 0.5), col, sw(4))

func _draw_icon_vibration(c: Vector2, s: float, col: Color):
	draw_rect(Rect2(c.x - s * 0.35, c.y - s * 0.8, s * 0.7, s * 1.6), col)
	draw_circle(Vector2(c.x, c.y + s * 0.5), s * 0.12, C_PANEL)
	draw_arc(c, s * 1.2, -PI * 0.7, -PI * 0.3, 8, col, sw(2))
	draw_arc(c, s * 1.2, PI * 0.3, PI * 0.7, 8, col, sw(2))

func _draw_icon_globe(c: Vector2, s: float, col: Color):
	draw_arc(c, s * 0.9, 0, TAU, 24, col, sw(2))
	draw_arc(c, s * 0.9, -PI / 2, PI / 2, 12, col, sw(2))
	draw_line(c + Vector2(-s * 0.9, 0), c + Vector2(s * 0.9, 0), col, sw(2))

func _draw_icon_weather(c: Vector2, s: float, col: Color):
	draw_circle(c + Vector2(-s * 0.3, s * 0.1), s * 0.5, col)
	draw_circle(c + Vector2(s * 0.3, s * 0.05), s * 0.55, col)
	draw_circle(c + Vector2(0, -s * 0.2), s * 0.5, col)

func _draw_icon_gift(c: Vector2, s: float, col: Color):
	draw_rect(Rect2(c.x - s * 0.75, c.y - s * 0.25, s * 1.5, s * 0.95), col)
	draw_rect(Rect2(c.x - s * 0.12, c.y - s * 0.25, s * 0.24, s * 0.95), N_PINK)
	draw_rect(Rect2(c.x - s * 0.75, c.y + s * 0.05, s * 1.5, s * 0.20), N_PINK)
	draw_circle(c + Vector2(-s * 0.18, -s * 0.42), s * 0.20, N_PINK)
	draw_circle(c + Vector2(s * 0.18, -s * 0.42), s * 0.20, N_PINK)

func _draw_icon_lightbulb(c: Vector2, s: float, col: Color):
	draw_circle(c + Vector2(0, -s * 0.15), s * 0.60, col)
	draw_rect(Rect2(c.x - s * 0.30, c.y + s * 0.40, s * 0.60, s * 0.18), Color(0.85, 0.75, 0.35))
	draw_rect(Rect2(c.x - s * 0.26, c.y + s * 0.62, s * 0.52, s * 0.14), Color(0.85, 0.75, 0.35))
	draw_rect(Rect2(c.x - s * 0.22, c.y + s * 0.80, s * 0.44, s * 0.12), Color(0.75, 0.65, 0.25))
	draw_circle(c + Vector2(-s * 0.20, -s * 0.30), s * 0.16, Color(1, 1, 1, 0.85))

func _draw_icon_video(c: Vector2, s: float, col: Color):
	draw_circle(c, s * 0.9, Color(col.r, col.g, col.b, 0.25))
	draw_arc(c, s * 0.9, 0, TAU, 24, col, sw(3))
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-s * 0.30, -s * 0.50), c + Vector2(s * 0.55, 0), c + Vector2(-s * 0.30, s * 0.50)]), col)

func _draw_icon_lock(c: Vector2, s: float, col: Color):
	draw_rect(Rect2(c.x - s * 0.55, c.y - s * 0.05, s * 1.1, s * 0.85), col)
	draw_arc(c + Vector2(0, -s * 0.30), s * 0.42, PI, TAU, 12, col, sw(3))

# ============================================================================
# PANELS
# ============================================================================

func _draw_panel(rect: Rect2, col: Color = C_PANEL, radius: float = 20.0, border_col: Color = C_BORDER):
	var r = int(radius * ui_scale)
	var s = StyleBoxFlat.new()
	s.bg_color = col
	s.set_corner_radius_all(r)
	s.border_width_top = int(2 * ui_scale); s.border_width_bottom = int(2 * ui_scale)
	s.border_width_left = int(2 * ui_scale); s.border_width_right = int(2 * ui_scale)
	s.border_color = border_col
	draw_style_box(s, rect)
	var hl = StyleBoxFlat.new()
	hl.bg_color = Color(1, 1, 1, 0.06)
	hl.corner_radius_top_left = r - 2
	hl.corner_radius_top_right = r - 2
	draw_style_box(hl, Rect2(rect.position + Vector2(2, 2) * ui_scale,
		Vector2(rect.size.x - 4 * ui_scale, rect.size.y * 0.4)))

func _draw_glow(rect: Rect2, col: Color, layers: int = 4, spread: float = 5.0, base_a: float = 0.20):
	for i in range(layers):
		var grow = (i + 1) * spread * ui_scale
		var gs = StyleBoxFlat.new()
		gs.bg_color = Color(col.r, col.g, col.b, base_a - i * (base_a / layers))
		gs.set_corner_radius_all(int(rect.size.y * 0.42) + int(grow))
		draw_style_box(gs, Rect2(rect.position - Vector2(grow, grow),
			rect.size + Vector2(grow * 2, grow * 2)))

func _draw_btn_3d(rect: Rect2, col_top: Color, col_shadow: Color, with_glow: bool = true):
	if with_glow and not reduce_effects:
		_draw_glow(rect, col_top, 3, 4.0, 0.22)
	var sh = StyleBoxFlat.new()
	sh.bg_color = col_shadow
	sh.set_corner_radius_all(int(rect.size.y * 0.42))
	draw_style_box(sh, Rect2(rect.position + Vector2(0, 6 * ui_scale), rect.size))
	var body = StyleBoxFlat.new()
	body.bg_color = col_top
	body.set_corner_radius_all(int(rect.size.y * 0.42))
	draw_style_box(body, rect)
	var gloss = StyleBoxFlat.new()
	gloss.bg_color = Color(1, 1, 1, 0.38)
	var ir = max(1, int(rect.size.y * 0.42) - 6)
	gloss.corner_radius_top_left = ir
	gloss.corner_radius_top_right = ir
	gloss.corner_radius_bottom_left = int(ir * 0.35)
	gloss.corner_radius_bottom_right = int(ir * 0.35)
	draw_style_box(gloss, Rect2(rect.position + Vector2(8 * ui_scale, 4 * ui_scale),
		Vector2(rect.size.x - 16 * ui_scale, rect.size.y * 0.40)))
	draw_line(rect.position + Vector2(rect.size.x * 0.15, 3 * ui_scale),
		rect.position + Vector2(rect.size.x * 0.85, 3 * ui_scale),
		Color(1, 1, 1, 0.55), sw(1.5))

# ============================================================================
# BLOCK RENDERING — 4 DIFFERENT STYLES
# ============================================================================

func _render_block_styled(rect: Rect2, color: Color, skin: Dictionary, alpha: float = 1.0):
	var style_id = skin.get("style", "neon")
	var radius_ratio = skin.get("corner", 0.28)
	var radius = int(rect.size.x * radius_ratio)
	var r = color.r; var g = color.g; var b = color.b
	var a = color.a * alpha

	# LOW
	if quality == Quality.LOW:
		var s = StyleBoxFlat.new()
		s.bg_color = Color(r, g, b, a)
		s.set_corner_radius_all(radius)
		draw_style_box(s, rect)
		var hl = StyleBoxFlat.new()
		hl.bg_color = Color(1, 1, 1, 0.30 * a)
		hl.corner_radius_top_left = radius
		hl.corner_radius_top_right = radius
		draw_style_box(hl, Rect2(rect.position + Vector2(4 * ui_scale, 3 * ui_scale),
			Vector2(rect.size.x - 8 * ui_scale, rect.size.y * 0.32)))
		return

	# OUTLINE
	if style_id == "outline":
		var s2 = StyleBoxFlat.new()
		s2.bg_color = Color(r * 0.10, g * 0.10, b * 0.18, a * 0.75)
		s2.set_corner_radius_all(radius)
		var bw = max(3, int(rect.size.x * 0.06))
		s2.border_width_top = bw; s2.border_width_bottom = bw
		s2.border_width_left = bw; s2.border_width_right = bw
		s2.border_color = Color(r, g, b, a)
		draw_style_box(s2, rect)
		draw_circle(rect.position + rect.size * 0.5, rect.size.x * 0.14, Color(r, g, b, a * 0.95))
		draw_circle(rect.position + rect.size * 0.5, rect.size.x * 0.06, Color(1, 1, 1, a * 0.9))
		return

	# SOFT
	if style_id == "soft":
		var sh_soft = StyleBoxFlat.new()
		sh_soft.bg_color = Color(r * 0.55, g * 0.55, b * 0.62, a * 0.75)
		sh_soft.set_corner_radius_all(radius)
		draw_style_box(sh_soft, Rect2(rect.position + Vector2(0, 3 * ui_scale), rect.size))
		var body_soft = StyleBoxFlat.new()
		body_soft.bg_color = Color(r, g, b, a).lerp(Color(1, 1, 1, a), 0.12)
		body_soft.set_corner_radius_all(radius)
		draw_style_box(body_soft, rect)
		var gloss_soft = StyleBoxFlat.new()
		gloss_soft.bg_color = Color(1, 1, 1, 0.32 * a)
		gloss_soft.corner_radius_top_left = radius
		gloss_soft.corner_radius_top_right = radius
		gloss_soft.corner_radius_bottom_left = int(radius * 0.8)
		gloss_soft.corner_radius_bottom_right = int(radius * 0.8)
		draw_style_box(gloss_soft, Rect2(rect.position + Vector2(3 * ui_scale, 3 * ui_scale),
			Vector2(rect.size.x - 6 * ui_scale, rect.size.y * 0.55)))
		var bot_soft = StyleBoxFlat.new()
		bot_soft.bg_color = Color(r * 0.70, g * 0.70, b * 0.80, a * 0.55)
		bot_soft.corner_radius_bottom_left = radius
		bot_soft.corner_radius_bottom_right = radius
		draw_style_box(bot_soft, Rect2(rect.position + Vector2(3 * ui_scale, rect.size.y * 0.70),
			Vector2(rect.size.x - 6 * ui_scale, rect.size.y * 0.28)))
		return

	# NEON
	if style_id == "neon":
		if not reduce_effects:
			for i in range(5):
				var grow = (i + 1) * 5.0 * ui_scale
				var gs = StyleBoxFlat.new()
				gs.bg_color = Color(r, g, b, (0.30 - i * 0.05) * a)
				gs.set_corner_radius_all(radius + int(grow))
				draw_style_box(gs, Rect2(rect.position - Vector2(grow, grow),
					rect.size + Vector2(grow * 2, grow * 2)))
		var sh_neon = StyleBoxFlat.new()
		sh_neon.bg_color = Color(r * 0.25, g * 0.25, b * 0.35, a)
		sh_neon.set_corner_radius_all(radius)
		draw_style_box(sh_neon, Rect2(rect.position + Vector2(0, 5 * ui_scale), rect.size))
		var body_neon = StyleBoxFlat.new()
		body_neon.bg_color = Color(r, g, b, a)
		body_neon.set_corner_radius_all(radius)
		draw_style_box(body_neon, rect)
		var core = StyleBoxFlat.new()
		core.bg_color = Color(min(1.0, r + 0.30), min(1.0, g + 0.30), min(1.0, b + 0.30), a * 0.85)
		core.set_corner_radius_all(max(1, radius - 4))
		draw_style_box(core, Rect2(rect.position + Vector2(rect.size.x * 0.14, rect.size.y * 0.14),
			rect.size * 0.72))
		var gloss_neon = StyleBoxFlat.new()
		gloss_neon.bg_color = Color(1, 1, 1, 0.55 * a)
		gloss_neon.corner_radius_top_left = max(1, radius - 4)
		gloss_neon.corner_radius_top_right = max(1, radius - 4)
		draw_style_box(gloss_neon, Rect2(rect.position + Vector2(6 * ui_scale, 5 * ui_scale),
			Vector2(rect.size.x - 12 * ui_scale, rect.size.y * 0.28)))
		if rect.size.x > 24 * ui_scale:
			var sp = rect.position + Vector2(rect.size.x * 0.28, rect.size.y * 0.24)
			draw_circle(sp, rect.size.x * 0.06, Color(1, 1, 1, a * 0.95))
		return

	# GLOW
	if style_id == "glow":
		if not reduce_effects:
			for i in range(6):
				var grow = (i + 1) * 7.0 * ui_scale
				var gs = StyleBoxFlat.new()
				gs.bg_color = Color(r, g, b, (0.32 - i * 0.05) * a)
				gs.set_corner_radius_all(radius + int(grow))
				draw_style_box(gs, Rect2(rect.position - Vector2(grow, grow),
					rect.size + Vector2(grow * 2, grow * 2)))
		var body_glow = StyleBoxFlat.new()
		body_glow.bg_color = Color(r, g, b, a * 0.85)
		body_glow.set_corner_radius_all(radius)
		draw_style_box(body_glow, rect)
		var core_glow = StyleBoxFlat.new()
		core_glow.bg_color = Color(min(1.0, r * 1.3 + 0.10), min(1.0, g * 1.3 + 0.10),
			min(1.0, b * 1.3 + 0.10), a * 0.9)
		core_glow.set_corner_radius_all(max(1, radius - 3))
		draw_style_box(core_glow, Rect2(rect.position + Vector2(rect.size.x * 0.20, rect.size.y * 0.20),
			rect.size * 0.60))
		draw_circle(rect.position + rect.size * 0.5, rect.size.x * 0.10, Color(1, 1, 1, a * 0.85))
		return

	# FALLBACK
	var sh = StyleBoxFlat.new()
	sh.bg_color = Color(r * 0.32, g * 0.32, b * 0.42, a)
	sh.set_corner_radius_all(radius)
	draw_style_box(sh, Rect2(rect.position + Vector2(0, 4.5 * ui_scale), rect.size))
	var body = StyleBoxFlat.new()
	body.bg_color = Color(r, g, b, a)
	body.set_corner_radius_all(radius)
	draw_style_box(body, rect)
	var gloss = StyleBoxFlat.new()
	gloss.bg_color = Color(1, 1, 1, 0.70 * a)
	gloss.corner_radius_top_left = max(1, radius - 3)
	gloss.corner_radius_top_right = max(1, radius - 3)
	draw_style_box(gloss, Rect2(rect.position + Vector2(5 * ui_scale, 4 * ui_scale),
		Vector2(rect.size.x - 10 * ui_scale, rect.size.y * 0.46)))

# ============================================================================
# ADS
# ============================================================================

const INTERSTITIAL_EVERY_N_GAMES = 3
var games_played_session = 0
var used_revive_this_game = false
var _ads: Node = null

func admob():
	if _ads == null: _ads = get_node_or_null("/root/MobileAds")
	return _ads

func load_interstitial_ad():
	var ads = admob()
	if ads and ads.has_method("load_interstitial"): ads.load_interstitial()

func show_interstitial_ad():
	var ads = admob()
	if ads and ads.has_method("show_interstitial"):
		ads.show_interstitial()
		call_deferred("load_interstitial_ad")

func show_rewarded_ad():
	var ads = admob()
	if ads and ads.has_method("show_rewarded"):
		ads.show_rewarded(); return
	if OS.is_debug_build(): grant_revive_reward()

func grant_revive_reward():
	if used_revive_this_game: return
	used_revive_this_game = true
	var candidates: Array = []
	for y in range(GRID_SIZE):
		var row_cnt = 0
		for x in range(GRID_SIZE):
			if grid[y][x] != null: row_cnt += 1
		for x in range(GRID_SIZE):
			if grid[y][x] == null: continue
			var col_cnt = 0
			for yy in range(GRID_SIZE):
				if grid[yy][x] != null: col_cnt += 1
			var neighbours = 0
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if dx == 0 and dy == 0: continue
					var nx = x + dx; var ny = y + dy
					if nx >= 0 and nx < GRID_SIZE and ny >= 0 and ny < GRID_SIZE:
						if grid[ny][nx] != null: neighbours += 1
			candidates.append({"x": x, "y": y, "p": row_cnt + col_cnt + neighbours})
	if not candidates.is_empty():
		candidates.sort_custom(func(a, b): return a.p > b.p)
		var freed = 0
		for c in candidates:
			if freed >= 8: break
			var cx = int(c.x); var cy = int(c.y)
			if grid[cy][cx] != null: grid[cy][cx] = null; freed += 1
	_last_piece_shapes.clear(); _last_piece_colors.clear()
	var attempts = 0
	while attempts < 30:
		generate_new_pieces()
		if has_valid_moves(): break
		attempts += 1
	if not has_valid_moves():
		for i in range(3):
			pieces[i] = {"blocks": [Vector2i(0, 0)],
				"color": COLOR_PALETTE[i % COLOR_PALETTE.size()], "type": "normal"}
	_mark_pieces_dirty(); _recalc_density()
	state = State.PLAYING
	save_game_state(); queue_redraw()

# ============================================================================
# AUDIO
# ============================================================================

var sound_enabled = true
var music_enabled = true
var vibration_enabled = true
var weather_mode = 1
var audio_started = false
var sfx_place: AudioStreamPlayer
var sfx_clear: AudioStreamPlayer
var sfx_bomb: AudioStreamPlayer
var sfx_combo: AudioStreamPlayer
var sfx_gameover: AudioStreamPlayer
var sfx_button: AudioStreamPlayer
var music_player: AudioStreamPlayer
var music_menu_track: AudioStream = null
var music_game_track: AudioStream = null
var current_music_state = 0

const CUSTOM_FONT_PATHS = ["res://fonts/custom_font.ttf", "res://fonts/custom_font.otf"]
var game_font: Font = null

func active_font() -> Font: return game_font if game_font != null else ThemeDB.fallback_font

func load_custom_font():
	for path in CUSTOM_FONT_PATHS:
		if ResourceLoader.exists(path):
			var f = load(path)
			if f is Font: game_font = f; return
	game_font = null

# ============================================================================
# LOCALIZATION
# ============================================================================

var current_lang = "ru"
const LANG_ORDER = ["ru", "en", "es", "de", "fr", "pt", "it", "tr"]

const STRINGS = {
	"ru": {"start_game": "Играть", "continue": "Продолжить", "settings": "Настройки",
		"skins": "Скины", "achievements": "Награды", "campaign": "Кампания",
		"settings_title": "НАСТРОЙКИ", "sound": "Звук", "music": "Музыка", "on": "Вкл", "off": "Выкл",
		"vibration": "Вибрация", "weather": "Погода", "reduce_effects": "Эффекты",
		"weather_off": "Выкл", "weather_snow": "Снег", "weather_rain": "Дождь",
		"reset_score": "Сброс", "back": "Назад", "language": "Язык",
		"pause_title": "ПАУЗА", "resume": "Продолжить", "restart": "Заново", "main_menu": "В меню",
		"score": "Счёт", "game_over_title": "ИГРА ОКОНЧЕНА", "watch_ad_continue": "Реклама",
		"mode_select": "ВЫБОР РЕЖИМА", "mode_classic": "Классика", "mode_classic_desc": "До проигрыша",
		"mode_time": "Время", "mode_time_desc": "60 сек — максимум очков",
		"mode_campaign": "Кампания", "mode_campaign_desc": "999 уровней",
		"skins_title": "СКИНЫ", "select": "Выбрать", "active": "Активно",
		"achievements_title": "НАГРАДЫ", "level": "Уровень",
		"moves": "Ходы: ", "time": "сек",
		"campaign_title": "КАМПАНИЯ", "win": "УРОВЕНЬ ПРОЙДЕН!", "lose": "УРОВЕНЬ ПРОВАЛЕН",
		"next_level": "Следующий", "retry": "Повторить", "unlocked": "Открыто",
		"loading": "Загрузка...", "by": "by mgz",
		"tip1": "Собирай линии для комбо!", "tip2": "Комбо x5 усиливает множитель",
		"tip3": "Бомба очищает 3×3", "tip4": "Стрелка стирает строку и столбец",
		"world_1": "Начало", "world_2": "Пустыня", "world_3": "Океан",
		"world_4": "Космос", "world_5": "Легенда",
		"goal_crystals": "Кристаллы", "goal_diamonds": "Алмазы", "goal_stars": "Звёзды",
		"best": "Рекорд", "tut_place_t": "Перетащи блок",
		"tut_place_d": "Нажми на фигуру внизу и тащи её на поле",
		"tut_lines_t": "Собирай линии", "tut_lines_d": "Заполни строку или столбец — они исчезнут",
		"tut_combo_t": "Комбо растёт", "tut_combo_d": "Собирай линии несколько ходов подряд!",
		"tut_ready_t": "Готов!", "tut_ready_d": "Играй и бей рекорды!",
		"tut_time_t1": "Режим Время", "tut_time_d1": "60 секунд — успей набрать максимум очков!",
		"tut_time_t2": "Линии дают время", "tut_time_d2": "Каждая линия = +2 секунды",
		"tut_next": "Далее", "tut_done": "Понятно!", "award_new": "НАГРАДА",
		"play_again": "Играть снова", "new_record": "НОВЫЙ РЕКОРД!",
		"yes": "Да", "no": "Нет", "exit_title": "ВЫХОД", "exit_msg": "Выйти из игры?",
		"no_internet": "Нет интернета",
		"revive_title": "ПРОДОЛЖИТЬ?", "revive_sub": "Посмотри рекламу и продолжи игру",
		"revive_btn": "ПРОДОЛЖИТЬ ИГРУ", "revive_no": "Нет, спасибо",
		"revive_gives": "+8 блоков убрано",
		"daily_bonus": "БОНУС ДНЯ"},
	"en": {"start_game": "Play", "continue": "Continue", "settings": "Settings",
		"skins": "Skins", "achievements": "Awards", "campaign": "Campaign",
		"settings_title": "SETTINGS", "sound": "Sound", "music": "Music", "on": "On", "off": "Off",
		"vibration": "Vibration", "weather": "Weather", "reduce_effects": "Effects",
		"weather_off": "Off", "weather_snow": "Snow", "weather_rain": "Rain",
		"reset_score": "Reset", "back": "Back", "language": "Language",
		"pause_title": "PAUSED", "resume": "Resume", "restart": "Restart", "main_menu": "Home",
		"score": "Score", "game_over_title": "GAME OVER", "watch_ad_continue": "Watch ad",
		"mode_select": "SELECT MODE", "mode_classic": "Classic", "mode_classic_desc": "Until game over",
		"mode_time": "Time", "mode_time_desc": "60 sec — max score",
		"mode_campaign": "Campaign", "mode_campaign_desc": "999 levels",
		"skins_title": "SKINS", "select": "Select", "active": "Active",
		"achievements_title": "AWARDS", "level": "Level",
		"moves": "Moves: ", "time": "sec",
		"campaign_title": "CAMPAIGN", "win": "LEVEL CLEARED!", "lose": "LEVEL FAILED",
		"next_level": "Next", "retry": "Retry", "unlocked": "Unlocked",
		"loading": "Loading...", "by": "by mgz",
		"tip1": "Collect lines for combos!", "tip2": "Combo x5 boosts multiplier",
		"tip3": "Bomb clears 3×3", "tip4": "Arrow clears row & column",
		"world_1": "Beginning", "world_2": "Desert", "world_3": "Ocean",
		"world_4": "Space", "world_5": "Legend",
		"goal_crystals": "Crystals", "goal_diamonds": "Diamonds", "goal_stars": "Stars",
		"best": "Best", "tut_place_t": "Drag a block",
		"tut_place_d": "Tap a piece below and drag it to the board",
		"tut_lines_t": "Collect lines", "tut_lines_d": "Fill a row or column — they disappear",
		"tut_combo_t": "Combos grow", "tut_combo_d": "Collect lines several turns in a row!",
		"tut_ready_t": "Ready!", "tut_ready_d": "Play and beat your records!",
		"tut_time_t1": "Time mode", "tut_time_d1": "60 seconds — score as much as you can!",
		"tut_time_t2": "Lines give time", "tut_time_d2": "Each cleared line = +2 seconds",
		"tut_next": "Next", "tut_done": "Got it!", "award_new": "AWARD",
		"play_again": "Play again", "new_record": "NEW RECORD!",
		"yes": "Yes", "no": "No", "exit_title": "EXIT", "exit_msg": "Quit the game?",
		"no_internet": "No internet",
		"revive_title": "CONTINUE?", "revive_sub": "Watch an ad and keep playing",
		"revive_btn": "CONTINUE GAME", "revive_no": "No thanks",
		"revive_gives": "+8 blocks cleared",
		"daily_bonus": "DAILY BONUS"},
	"es": {"start_game": "Jugar", "continue": "Continuar", "settings": "Ajustes",
		"skins": "Estilos", "achievements": "Logros", "campaign": "Campaña",
		"settings_title": "AJUSTES", "sound": "Sonido", "music": "Música", "on": "Sí", "off": "No",
		"vibration": "Vibración", "weather": "Clima", "reduce_effects": "Efectos",
		"weather_off": "Apagado", "weather_snow": "Nieve", "weather_rain": "Lluvia",
		"reset_score": "Borrar", "back": "Atrás", "language": "Idioma",
		"pause_title": "PAUSA", "resume": "Continuar", "restart": "Reiniciar", "main_menu": "Menú",
		"score": "Puntos", "game_over_title": "FIN", "watch_ad_continue": "Ver anuncio",
		"mode_select": "ELEGIR MODO", "mode_classic": "Clásico", "mode_classic_desc": "Hasta perder",
		"mode_time": "Tiempo", "mode_time_desc": "60 seg — máx puntos",
		"mode_campaign": "Campaña", "mode_campaign_desc": "999 niveles",
		"skins_title": "ESTILOS", "select": "Elegir", "active": "Activo",
		"achievements_title": "LOGROS", "level": "Nivel",
		"moves": "Movs: ", "time": "seg",
		"campaign_title": "CAMPAÑA", "win": "¡NIVEL SUPERADO!", "lose": "NIVEL FALLIDO",
		"next_level": "Siguiente", "retry": "Reintentar", "unlocked": "Desbloqueado",
		"loading": "Cargando...", "by": "by mgz",
		"tip1": "¡Recoge líneas para combos!", "tip2": "Combo x5 mejora el multiplicador",
		"tip3": "La bomba limpia 3×3", "tip4": "La flecha limpia fila y columna",
		"world_1": "Inicio", "world_2": "Desierto", "world_3": "Océano",
		"world_4": "Espacio", "world_5": "Leyenda",
		"goal_crystals": "Cristales", "goal_diamonds": "Diamantes", "goal_stars": "Estrellas",
		"best": "Mejor", "tut_place_t": "Arrastra un bloque",
		"tut_place_d": "Toca una pieza y arrástrala al campo",
		"tut_lines_t": "Recoge líneas", "tut_lines_d": "Llena una fila o columna — desaparecerán",
		"tut_combo_t": "Los combos crecen", "tut_combo_d": "¡Recoge líneas varios turnos seguidos!",
		"tut_ready_t": "¡Listo!", "tut_ready_d": "¡Juega y bate récords!",
		"tut_time_t1": "Modo Tiempo", "tut_time_d1": "60 segundos — ¡máximo de puntos!",
		"tut_time_t2": "Líneas dan tiempo", "tut_time_d2": "Cada línea = +2 segundos",
		"tut_next": "Siguiente", "tut_done": "¡Entendido!", "award_new": "LOGRO",
		"play_again": "Jugar de nuevo", "new_record": "¡NUEVO RÉCORD!",
		"yes": "Sí", "no": "No", "exit_title": "SALIR", "exit_msg": "¿Salir del juego?",
		"no_internet": "Sin internet",
		"revive_title": "¿CONTINUAR?", "revive_sub": "Mira un anuncio y sigue jugando",
		"revive_btn": "CONTINUAR", "revive_no": "No, gracias",
		"revive_gives": "+8 bloques limpiados",
		"daily_bonus": "BONO DIARIO"},
	"de": {"start_game": "Spielen", "continue": "Fortsetzen", "settings": "Einstellungen",
		"skins": "Skins", "achievements": "Erfolge", "campaign": "Kampagne",
		"settings_title": "EINSTELLUNGEN", "sound": "Ton", "music": "Musik", "on": "Ein", "off": "Aus",
		"vibration": "Vibration", "weather": "Wetter", "reduce_effects": "Effekte",
		"weather_off": "Aus", "weather_snow": "Schnee", "weather_rain": "Regen",
		"reset_score": "Löschen", "back": "Zurück", "language": "Sprache",
		"pause_title": "PAUSE", "resume": "Weiter", "restart": "Neustart", "main_menu": "Menü",
		"score": "Punkte", "game_over_title": "VORBEI", "watch_ad_continue": "Werbung",
		"mode_select": "MODUS", "mode_classic": "Klassisch", "mode_classic_desc": "Bis zum Ende",
		"mode_time": "Zeit", "mode_time_desc": "60 Sek — max Punkte",
		"mode_campaign": "Kampagne", "mode_campaign_desc": "999 Level",
		"skins_title": "SKINS", "select": "Wählen", "active": "Aktiv",
		"achievements_title": "ERFOLGE", "level": "Level",
		"moves": "Züge: ", "time": "Sek",
		"campaign_title": "KAMPAGNE", "win": "LEVEL GESCHAFFT!", "lose": "FEHLGESCHLAGEN",
		"next_level": "Weiter", "retry": "Nochmal", "unlocked": "Frei",
		"loading": "Lädt...", "by": "by mgz",
		"tip1": "Sammle Linien für Combos!", "tip2": "Combo x5 verstärkt Multiplikator",
		"tip3": "Bombe räumt 3×3", "tip4": "Pfeil räumt Zeile & Spalte",
		"world_1": "Anfang", "world_2": "Wüste", "world_3": "Ozean",
		"world_4": "Weltraum", "world_5": "Legende",
		"goal_crystals": "Kristalle", "goal_diamonds": "Diamanten", "goal_stars": "Sterne",
		"best": "Rekord", "tut_place_t": "Ziehe einen Block",
		"tut_place_d": "Tippe auf eine Figur und ziehe sie aufs Feld",
		"tut_lines_t": "Sammle Linien", "tut_lines_d": "Fülle eine Reihe oder Spalte — sie verschwinden",
		"tut_combo_t": "Combos wachsen", "tut_combo_d": "Sammle Linien mehrere Züge hintereinander!",
		"tut_ready_t": "Bereit!", "tut_ready_d": "Spiele und schlage Rekorde!",
		"tut_time_t1": "Zeitmodus", "tut_time_d1": "60 Sekunden — so viele Punkte wie möglich!",
		"tut_time_t2": "Linien geben Zeit", "tut_time_d2": "Jede Linie = +2 Sekunden",
		"tut_next": "Weiter", "tut_done": "Verstanden!", "award_new": "ERFOLG",
		"play_again": "Nochmal", "new_record": "NEUER REKORD!",
		"yes": "Ja", "no": "Nein", "exit_title": "BEENDEN", "exit_msg": "Spiel verlassen?",
		"no_internet": "Kein Internet",
		"revive_title": "WEITER?", "revive_sub": "Sieh eine Werbung und spiele weiter",
		"revive_btn": "WEITER SPIELEN", "revive_no": "Nein, danke",
		"revive_gives": "+8 Blöcke entfernt",
		"daily_bonus": "TAGESBONUS"},
	"fr": {"start_game": "Jouer", "continue": "Continuer", "settings": "Réglages",
		"skins": "Styles", "achievements": "Succès", "campaign": "Campagne",
		"settings_title": "RÉGLAGES", "sound": "Son", "music": "Musique", "on": "Oui", "off": "Non",
		"vibration": "Vibration", "weather": "Météo", "reduce_effects": "Effets",
		"weather_off": "Off", "weather_snow": "Neige", "weather_rain": "Pluie",
		"reset_score": "Reset", "back": "Retour", "language": "Langue",
		"pause_title": "PAUSE", "resume": "Reprendre", "restart": "Relancer", "main_menu": "Menu",
		"score": "Score", "game_over_title": "TERMINÉ", "watch_ad_continue": "Publicité",
		"mode_select": "CHOISIR", "mode_classic": "Classique", "mode_classic_desc": "Jusqu'à perdre",
		"mode_time": "Temps", "mode_time_desc": "60 sec — max score",
		"mode_campaign": "Campagne", "mode_campaign_desc": "999 niveaux",
		"skins_title": "STYLES", "select": "Choisir", "active": "Actif",
		"achievements_title": "SUCCÈS", "level": "Niveau",
		"moves": "Coups: ", "time": "sec",
		"campaign_title": "CAMPAGNE", "win": "NIVEAU RÉUSSI!", "lose": "ÉCHEC",
		"next_level": "Suivant", "retry": "Réessayer", "unlocked": "Débloqué",
		"loading": "Chargement...", "by": "by mgz",
		"tip1": "Collecte les lignes pour les combos!", "tip2": "Combo x5 boost le multiplicateur",
		"tip3": "La bombe efface 3×3", "tip4": "La flèche efface ligne & colonne",
		"world_1": "Début", "world_2": "Désert", "world_3": "Océan",
		"world_4": "Espace", "world_5": "Légende",
		"goal_crystals": "Cristaux", "goal_diamonds": "Diamants", "goal_stars": "Étoiles",
		"best": "Record", "tut_place_t": "Glisse un bloc",
		"tut_place_d": "Touche une pièce et glisse-la sur le plateau",
		"tut_lines_t": "Collecte les lignes", "tut_lines_d": "Remplis une ligne ou colonne",
		"tut_combo_t": "Les combos grandissent", "tut_combo_d": "Collecte des lignes plusieurs tours!",
		"tut_ready_t": "Prêt!", "tut_ready_d": "Joue et bats des records!",
		"tut_time_t1": "Mode Temps", "tut_time_d1": "60 secondes — un max de points !",
		"tut_time_t2": "Les lignes donnent du temps", "tut_time_d2": "Chaque ligne = +2 secondes",
		"tut_next": "Suivant", "tut_done": "Compris!", "award_new": "SUCCÈS",
		"play_again": "Rejouer", "new_record": "NOUVEAU RECORD !",
		"yes": "Oui", "no": "Non", "exit_title": "QUITTER", "exit_msg": "Quitter le jeu ?",
		"no_internet": "Pas de connexion",
		"revive_title": "CONTINUER ?", "revive_sub": "Regarde une pub et continue",
		"revive_btn": "CONTINUER", "revive_no": "Non merci",
		"revive_gives": "+8 blocs effacés",
		"daily_bonus": "BONUS QUOTIDIEN"},
	"pt": {"start_game": "Jogar", "continue": "Continuar", "settings": "Ajustes",
		"skins": "Estilos", "achievements": "Conquistas", "campaign": "Campanha",
		"settings_title": "AJUSTES", "sound": "Som", "music": "Música", "on": "Sim", "off": "Não",
		"vibration": "Vibração", "weather": "Clima", "reduce_effects": "Efeitos",
		"weather_off": "Desligado", "weather_snow": "Neve", "weather_rain": "Chuva",
		"reset_score": "Limpar", "back": "Voltar", "language": "Idioma",
		"pause_title": "PAUSA", "resume": "Continuar", "restart": "Reiniciar", "main_menu": "Menu",
		"score": "Pontos", "game_over_title": "FIM", "watch_ad_continue": "Anúncio",
		"mode_select": "MODO", "mode_classic": "Clássico", "mode_classic_desc": "Até perder",
		"mode_time": "Tempo", "mode_time_desc": "60 seg — máx pontos",
		"mode_campaign": "Campanha", "mode_campaign_desc": "999 níveis",
		"skins_title": "ESTILOS", "select": "Escolher", "active": "Ativo",
		"achievements_title": "CONQUISTAS", "level": "Nível",
		"moves": "Jogadas: ", "time": "seg",
		"campaign_title": "CAMPANHA", "win": "NÍVEL COMPLETO!", "lose": "FALHOU",
		"next_level": "Próximo", "retry": "Tentar", "unlocked": "Liberado",
		"loading": "Carregando...", "by": "by mgz",
		"tip1": "Junte linhas para combos!", "tip2": "Combo x5 aumenta multiplicador",
		"tip3": "Bomba limpa 3×3", "tip4": "Seta limpa linha & coluna",
		"world_1": "Início", "world_2": "Deserto", "world_3": "Oceano",
		"world_4": "Espaço", "world_5": "Lenda",
		"goal_crystals": "Cristais", "goal_diamonds": "Diamantes", "goal_stars": "Estrelas",
		"best": "Recorde", "tut_place_t": "Arraste um bloco",
		"tut_place_d": "Toque numa peça e arraste para o campo",
		"tut_lines_t": "Junte linhas", "tut_lines_d": "Preencha linha ou coluna — desaparecem",
		"tut_combo_t": "Combos crescem", "tut_combo_d": "Junte linhas vários turnos seguidos!",
		"tut_ready_t": "Pronto!", "tut_ready_d": "Jogue e bata recordes!",
		"tut_time_t1": "Modo Tempo", "tut_time_d1": "60 segundos — máximo de pontos!",
		"tut_time_t2": "Linhas dão tempo", "tut_time_d2": "Cada linha = +2 segundos",
		"tut_next": "Próximo", "tut_done": "Entendi!", "award_new": "CONQUISTA",
		"play_again": "Jogar de novo", "new_record": "NOVO RECORDE!",
		"yes": "Sim", "no": "Não", "exit_title": "SAIR", "exit_msg": "Sair do jogo?",
		"no_internet": "Sem internet",
		"revive_title": "CONTINUAR?", "revive_sub": "Veja um anúncio e continue",
		"revive_btn": "CONTINUAR JOGO", "revive_no": "Não, obrigado",
		"revive_gives": "+8 blocos limpos",
		"daily_bonus": "BÔNUS DIÁRIO"},
	"it": {"start_game": "Gioca", "continue": "Continua", "settings": "Impostazioni",
		"skins": "Stili", "achievements": "Obiettivi", "campaign": "Campagna",
		"settings_title": "IMPOSTAZIONI", "sound": "Audio", "music": "Musica", "on": "Sì", "off": "No",
		"vibration": "Vibrazione", "weather": "Meteo", "reduce_effects": "Effetti",
		"weather_off": "Spento", "weather_snow": "Neve", "weather_rain": "Pioggia",
		"reset_score": "Reset", "back": "Indietro", "language": "Lingua",
		"pause_title": "PAUSA", "resume": "Riprendi", "restart": "Ricomincia", "main_menu": "Menu",
		"score": "Punti", "game_over_title": "FINE", "watch_ad_continue": "Pubblicità",
		"mode_select": "MODALITÀ", "mode_classic": "Classico", "mode_classic_desc": "Fino alla fine",
		"mode_time": "Tempo", "mode_time_desc": "60 sec — max punti",
		"mode_campaign": "Campagna", "mode_campaign_desc": "999 livelli",
		"skins_title": "STILI", "select": "Scegli", "active": "Attivo",
		"achievements_title": "OBIETTIVI", "level": "Livello",
		"moves": "Mosse: ", "time": "sec",
		"campaign_title": "CAMPAGNA", "win": "LIVELLO FINITO!", "lose": "FALLITO",
		"next_level": "Avanti", "retry": "Riprova", "unlocked": "Sbloccato",
		"loading": "Caricamento...", "by": "by mgz",
		"tip1": "Raccogli linee per combo!", "tip2": "Combo x5 potenzia il moltiplicatore",
		"tip3": "La bomba pulisce 3×3", "tip4": "La freccia pulisce riga & colonna",
		"world_1": "Inizio", "world_2": "Deserto", "world_3": "Oceano",
		"world_4": "Spazio", "world_5": "Leggenda",
		"goal_crystals": "Cristalli", "goal_diamonds": "Diamanti", "goal_stars": "Stelle",
		"best": "Record", "tut_place_t": "Trascina un blocco",
		"tut_place_d": "Tocca un pezzo e trascinalo sul campo",
		"tut_lines_t": "Raccogli linee", "tut_lines_d": "Riempi riga o colonna — spariranno",
		"tut_combo_t": "I combo crescono", "tut_combo_d": "Raccogli linee più turni di fila!",
		"tut_ready_t": "Pronto!", "tut_ready_d": "Gioca e batti i record!",
		"tut_time_t1": "Modalità Tempo", "tut_time_d1": "60 secondi — massimo punteggio!",
		"tut_time_t2": "Le linee danno tempo", "tut_time_d2": "Ogni linea = +2 secondi",
		"tut_next": "Avanti", "tut_done": "Capito!", "award_new": "OBIETTIVO",
		"play_again": "Gioca ancora", "new_record": "NUOVO RECORD!",
		"yes": "Sì", "no": "No", "exit_title": "ESCI", "exit_msg": "Uscire dal gioco?",
		"no_internet": "Nessuna connessione",
		"revive_title": "CONTINUARE?", "revive_sub": "Guarda un annuncio e continua",
		"revive_btn": "CONTINUA", "revive_no": "No, grazie",
		"revive_gives": "+8 blocchi rimossi",
		"daily_bonus": "BONUS GIORNALIERO"},
	"tr": {"start_game": "Oyna", "continue": "Devam", "settings": "Ayarlar",
		"skins": "Stiller", "achievements": "Başarılar", "campaign": "Kampanya",
		"settings_title": "AYARLAR", "sound": "Ses", "music": "Müzik", "on": "Açık", "off": "Kapalı",
		"vibration": "Titreşim", "weather": "Hava", "reduce_effects": "Efektler",
		"weather_off": "Kapalı", "weather_snow": "Kar", "weather_rain": "Yağmur",
		"reset_score": "Sıfırla", "back": "Geri", "language": "Dil",
		"pause_title": "DURAKLADI", "resume": "Devam", "restart": "Yeniden", "main_menu": "Menü",
		"score": "Puan", "game_over_title": "OYUN BİTTİ", "watch_ad_continue": "Reklam",
		"mode_select": "MOD SEÇ", "mode_classic": "Klasik", "mode_classic_desc": "Kaybedene kadar",
		"mode_time": "Zaman", "mode_time_desc": "60 sn — max puan",
		"mode_campaign": "Kampanya", "mode_campaign_desc": "999 seviye",
		"skins_title": "STİLLER", "select": "Seç", "active": "Aktif",
		"achievements_title": "BAŞARILAR", "level": "Seviye",
		"moves": "Hamle: ", "time": "sn",
		"campaign_title": "KAMPANYA", "win": "SEVİYE GEÇİLDİ!", "lose": "BAŞARISIZ",
		"next_level": "Sonraki", "retry": "Tekrar", "unlocked": "Açık",
		"loading": "Yükleniyor...", "by": "by mgz",
		"tip1": "Kombo için satır topla!", "tip2": "Kombo x5 çarpanı artırır",
		"tip3": "Bomba 3×3 temizler", "tip4": "Ok satır & sütunu temizler",
		"world_1": "Başlangıç", "world_2": "Çöl", "world_3": "Okyanus",
		"world_4": "Uzay", "world_5": "Efsane",
		"goal_crystals": "Kristaller", "goal_diamonds": "Elmaslar", "goal_stars": "Yıldızlar",
		"best": "Rekor", "tut_place_t": "Blok sürükle",
		"tut_place_d": "Alttaki parçaya dokun ve tahtaya sürükle",
		"tut_lines_t": "Satır topla", "tut_lines_d": "Satır veya sütunu doldur — kaybolurlar",
		"tut_combo_t": "Kombolar büyür", "tut_combo_d": "Üst üste birkaç tur satır topla!",
		"tut_ready_t": "Hazır!", "tut_ready_d": "Oyna ve rekorları kır!",
		"tut_time_t1": "Zaman modu", "tut_time_d1": "60 saniye — maksimum puan!",
		"tut_time_t2": "Satırlar zaman verir", "tut_time_d2": "Her satır = +2 saniye",
		"tut_next": "Sonraki", "tut_done": "Anladım!", "award_new": "BAŞARI",
		"play_again": "Tekrar oyna", "new_record": "YENİ REKOR!",
		"yes": "Evet", "no": "Hayır", "exit_title": "ÇIKIŞ", "exit_msg": "Oyundan çıkılsın mı?",
		"no_internet": "İnternet yok",
		"revive_title": "DEVAM?", "revive_sub": "Reklam izle ve oynamaya devam et",
		"revive_btn": "DEVAM ET", "revive_no": "Hayır, teşekkürler",
		"revive_gives": "+8 blok temizlendi",
		"daily_bonus": "GÜNLÜK BONUS"},
}

func tr_(key: String) -> String:
	if STRINGS.has(current_lang):
		var d = STRINGS[current_lang]
		if d.has(key): return d[key]
	if STRINGS.has("en") and STRINGS["en"].has(key): return STRINGS["en"][key]
	if STRINGS.has("ru") and STRINGS["ru"].has(key): return STRINGS["ru"][key]
	return key

func _next_language():
	var idx = LANG_ORDER.find(current_lang)
	if idx == -1: idx = 0
	current_lang = LANG_ORDER[(idx + 1) % LANG_ORDER.size()]

# ============================================================================
# SHAPES
# ============================================================================

var ALL_SHAPES = [
	[Vector2i(0,0)], [Vector2i(0,0), Vector2i(1,0)], [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(4,0)],
	[Vector2i(0,0), Vector2i(0,1)], [Vector2i(0,0), Vector2i(0,1), Vector2i(0,2)],
	[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(0,3)],
	[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(0,3), Vector2i(0,4)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1),
	 Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)],
	[Vector2i(0,0), Vector2i(0,1), Vector2i(1,1)], [Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1)], [Vector2i(0,0), Vector2i(1,0), Vector2i(1,1)],
	[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(1,2)],
	[Vector2i(1,0), Vector2i(1,1), Vector2i(1,2), Vector2i(0,2)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(0,2)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(1,2)],
	[Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(2,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1)],
	[Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(1,2)],
	[Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)],
	[Vector2i(0,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2), Vector2i(1,2)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)],
]

const SMALL_SHAPE_IDX = [0, 1, 5, 11, 12, 13, 14]
var SPECIAL_SHAPES = [ALL_SHAPES[0], ALL_SHAPES[1], ALL_SHAPES[2], ALL_SHAPES[5], ALL_SHAPES[6], ALL_SHAPES[9]]

const BOMB_CHANCE = 0.030
const LINE_CLEAR_CHANCE = 0.035
const BOMB_MIN_INTERVAL = 6
const LINE_MIN_INTERVAL = 5
const BOMB_COLOR = Color(0.18, 0.10, 0.35)
const LINE_CLEAR_COLOR = Color(1.0, 0.85, 0.15)

# ============================================================================
# STATE / PIECES
# ============================================================================

var pieces = []
var dragging_piece = -1
var drag_offset = Vector2.ZERO
var mouse_pos = Vector2.ZERO
var pop_cells = []
var flash_cells = []
var combo_popups = []
var visual_effects = []
var explosion_rings = []
var drag_trail: Array = []
var confetti: Array = []
var snowflakes: Array = []
var flash_alpha: float = 0.0

const SCORE_ANIM_SPEED = 6.0
var displayed_score = 0.0
const PIECE_SPAWN_DURATION = 0.25
var piece_spawn_timers = [0.0, 0.0, 0.0]
var _piece_has_spot_cache: Array = []
var _piece_has_spot_dirty: bool = true

func _mark_pieces_dirty(): _piece_has_spot_dirty = true

func _recalc_pieces_has_spot():
	_piece_has_spot_dirty = false
	_piece_has_spot_cache.clear()
	for piece in pieces:
		if piece["blocks"].is_empty(): _piece_has_spot_cache.append(true); continue
		var found = false
		for y in range(GRID_SIZE):
			for x in range(GRID_SIZE):
				if can_place_piece(piece["blocks"], x, y): found = true; break
			if found: break
		_piece_has_spot_cache.append(found)

const BACK_BUTTON = Rect2(280, 1480, 340, 65)
var menu_blocks: Array = []
var campaign_page: int = 0
var _skin_back_rect: Rect2 = Rect2(0, 0, 0, 0)

func _init_menu_blocks():
	menu_blocks.clear()
	for i in range(14):
		menu_blocks.append({
			"x": randf_range(0, REF_SIZE.x), "y": randf_range(0, REF_SIZE.y),
			"size": randf_range(40, 85), "speed": randf_range(10, 28),
			"rot": randf_range(0, TAU), "rot_speed": randf_range(-0.8, 0.8),
			"color": COLOR_PALETTE[randi() % COLOR_PALETTE.size()], "alpha": randf_range(0.10, 0.28)
		})
	snowflakes.clear()
	if weather_mode == 1:
		for i in range(34):
			snowflakes.append({"x": randf_range(0, REF_SIZE.x), "y": randf_range(0, REF_SIZE.y),
				"size": randf_range(2.5, 6.0), "speed_y": randf_range(15.0, 45.0),
				"speed_x": randf_range(-12.0, 12.0), "phase": randf_range(0.0, TAU)})
	elif weather_mode == 2:
		for i in range(60):
			snowflakes.append({"x": randf_range(0, REF_SIZE.x), "y": randf_range(0, REF_SIZE.y),
				"size": randf_range(1.5, 3.0), "speed_y": randf_range(280.0, 500.0),
				"speed_x": randf_range(-8.0, -3.0), "phase": randf_range(0.0, TAU)})

func _update_menu_blocks(delta):
	for b in menu_blocks:
		b.y -= b.speed * delta
		b.rot += b.rot_speed * delta
		if b.y < -120: b.y = REF_SIZE.y + 120; b.x = randf_range(0, REF_SIZE.x)
	for s in snowflakes:
		s.y += s.speed_y * delta
		if weather_mode == 1: s.phase += delta * 1.5; s.x += sin(s.phase) * s.speed_x * delta
		else: s.x += s.speed_x * delta
		if s.y > REF_SIZE.y + 30: s.y = -30; s.x = randf_range(0, REF_SIZE.x)

func _draw_menu_blocks():
	for b in menu_blocks:
		var center = to_screen(Vector2(b.x, b.y))
		var sz = b.size * ui_scale
		var col = Color(b.color.r, b.color.g, b.color.b, b.alpha)
		var half = sz / 2.0
		var cos_r = cos(b.rot); var sin_r = sin(b.rot)
		var pts = PackedVector2Array()
		for corner in [Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)]:
			pts.append(center + Vector2(corner.x * cos_r - corner.y * sin_r, corner.x * sin_r + corner.y * cos_r))
		draw_colored_polygon(pts, col)
	for s in snowflakes:
		var pos = to_screen(Vector2(s.x, s.y))
		if weather_mode == 1:
			draw_circle(pos, s["size"] * ui_scale, Color(1, 1, 1, 0.55))
			draw_circle(pos, s["size"] * ui_scale * 0.4, Color(1, 1, 1, 0.9))
		else:
			draw_line(pos, pos + Vector2(2 * ui_scale, s["size"] * 5 * ui_scale), Color(0.6, 0.85, 1.0, 0.55), sw(2))

# ============================================================================
# LAYOUT
# ============================================================================

func _menu_button_rects() -> Dictionary:
	var vp = get_viewport_rect().size
	var cx = vp.x / 2.0
	var bottom_safe = _safe_insets.w
	var play_w = min(vp.x * 0.72, 560 * ui_scale)
	var play_h = min(130 * ui_scale, vp.y * 0.085)
	var gap = max(12 * ui_scale, 14.0)
	var bw = (play_w - gap) / 2.0
	var bh = min(84 * ui_scale, vp.y * 0.058)
	var daily_h = min(70 * ui_scale, vp.y * 0.048)
	var stats_h = min(78 * ui_scale, vp.y * 0.052)
	var logo_zone_bottom = vp.y * 0.36
	var daily_y = logo_zone_bottom + 8 * ui_scale
	var daily_h_eff = daily_h if daily_bonus_available else 0.0
	var stats_gap = 10 * ui_scale if daily_bonus_available else 0.0
	var stats_y = daily_y + daily_h_eff + stats_gap
	var play_y = stats_y + stats_h + 20 * ui_scale
	var grid_y = play_y + play_h + gap
	var toggle_y = vp.y - bottom_safe - 90 * ui_scale
	var needed_bottom = grid_y + bh * 2 + gap
	if needed_bottom > toggle_y - 16 * ui_scale:
		var overflow = needed_bottom - (toggle_y - 16 * ui_scale)
		play_y = max(stats_y + stats_h + 12 * ui_scale, play_y - overflow)
		grid_y = play_y + play_h + gap
	var daily_w = min(vp.x * 0.62, 360 * ui_scale)
	var stats_w = min(vp.x * 0.86, 640 * ui_scale)
	return {
		"play": Rect2(cx - play_w / 2.0, play_y, play_w, play_h),
		"settings": Rect2(cx - play_w / 2.0, grid_y, bw, bh),
		"skins": Rect2(cx + gap / 2.0, grid_y, bw, bh),
		"achievements": Rect2(cx - play_w / 2.0, grid_y + bh + gap, bw, bh),
		"continue": Rect2(cx + gap / 2.0, grid_y + bh + gap, bw, bh),
		"daily": Rect2(cx - daily_w / 2.0, daily_y, daily_w, daily_h),
		"stats": Rect2(cx - stats_w / 2.0, stats_y, stats_w, stats_h),
		"toggle_sound": Rect2(30 * ui_scale + _safe_insets.x, toggle_y, 60 * ui_scale, 60 * ui_scale),
		"toggle_music": Rect2(106 * ui_scale + _safe_insets.x, toggle_y, 60 * ui_scale, 60 * ui_scale),
		"toggle_settings": Rect2(182 * ui_scale + _safe_insets.x, toggle_y, 60 * ui_scale, 60 * ui_scale),
	}

func _update_safe_area():
	if not OS.has_feature("mobile") and not OS.has_feature("web"):
		_safe_insets = Vector4.ZERO; return
	var safe = DisplayServer.get_display_safe_area()
	var vp_size = DisplayServer.window_get_size()
	if safe.size.x <= 0 or safe.size.y <= 0 or vp_size.x <= 0 or vp_size.y <= 0:
		_safe_insets = Vector4.ZERO; return
	var scale_x = float(get_viewport_rect().size.x) / float(vp_size.x)
	var scale_y = float(get_viewport_rect().size.y) / float(vp_size.y)
	_safe_insets = Vector4(
		float(safe.position.x) * scale_x,
		float(safe.position.y) * scale_y,
		float(vp_size.x - safe.position.x - safe.size.x) * scale_x,
		float(vp_size.y - safe.position.y - safe.size.y) * scale_y)

# ============================================================================
# READY
# ============================================================================

func _ready():
	randomize()
	load_high_score(); load_time_high(); load_settings(); load_skin()
	load_progress(); load_daily(); _check_time_of_day()
	has_saved_game = FileAccess.file_exists(GAME_SAVE_PATH)
	reset_grid()
	get_viewport().size_changed.connect(update_layout)
	update_layout()
	_update_safe_area()
	setup_audio(); load_custom_font(); _detect_quality()
	_apply_fps_cap()
	init_particles(); _init_menu_blocks()
	stats.skins_used[current_skin_id] = true
	call_deferred("load_interstitial_ad")
	check_achievements(); save_progress()
	state = State.LOADING
	loading_progress = 0.0; loading_elapsed = 0.0
	queue_redraw(); displayed_score = score

func _apply_fps_cap():
	match quality:
		Quality.LOW: Engine.max_fps = FPS_LOW
		_: Engine.max_fps = FPS_HIGH

func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if state == State.PLAYING:
			if game_mode == GameMode.TIME and score > time_high:
				time_high = score; save_time_high()
			if game_mode == GameMode.CLASSIC and score > high_score:
				high_score = score; save_high_score()
			pause_game()
		if music_player != null and music_player.playing: music_player.stream_paused = true
		save_settings(); save_progress()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		if music_player != null: music_player.stream_paused = false
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		if state == State.PLAYING: save_game_state()
		save_settings(); save_progress()
		get_tree().quit()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_handle_back_button()

func _handle_back_button():
	match state:
		State.PLAYING: pause_game()
		State.PAUSED: resume_game()
		State.SETTINGS:
			state = settings_return_state
			if state == State.MENU: _menu_enter_t = 0.0
		State.SKINS, State.ACHIEVEMENTS, State.MODE_SELECT:
			state = State.MENU; _menu_enter_t = 0.0
		State.CAMPAIGN_MAP:
			state = State.MODE_SELECT
		State.GAME_OVER: state = State.MENU; _menu_enter_t = 0.0
		State.REVIVE: revive_decline()
		State.MENU:
			if OS.is_debug_build(): get_tree().quit()
		State.TUTORIAL: advance_tutorial()
		_: pass

func create_player(path: String) -> AudioStreamPlayer:
	var p = AudioStreamPlayer.new()
	if ResourceLoader.exists(path): p.stream = load(path)
	add_child(p); return p

func setup_audio():
	sfx_place = create_player("res://sounds/place.wav")
	sfx_clear = create_player("res://sounds/clear.wav")
	sfx_bomb = create_player("res://sounds/bomb.wav")
	sfx_combo = create_player("res://sounds/combo.wav")
	sfx_gameover = create_player("res://sounds/gameover.wav")
	sfx_button = create_player("res://sounds/button.wav")
	if ResourceLoader.exists("res://sounds/music_menu.ogg"): music_menu_track = load("res://sounds/music_menu.ogg")
	if ResourceLoader.exists("res://sounds/music_game.ogg"): music_game_track = load("res://sounds/music_game.ogg")
	if music_game_track == null: music_game_track = music_menu_track
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"; music_player.volume_db = -12.0
	add_child(music_player)
	music_player.finished.connect(_on_music_finished)
	if not OS.has_feature("mobile") and not OS.has_feature("web"):
		audio_started = true; update_music_for_state(1)

func play_sfx(player: AudioStreamPlayer, pitch: float = 1.0):
	if sound_enabled and player != null and player.stream != null:
		player.pitch_scale = pitch; player.play()

func play_music(track: AudioStream):
	if track == null or music_player == null: return
	if not music_enabled: return
	if music_player.stream == track and music_player.playing: return
	music_player.stream = track; music_player.play()

func stop_music():
	if music_player != null and music_player.playing: music_player.stop()

func update_music_for_state(new_state: int):
	if new_state == current_music_state: return
	current_music_state = new_state
	match new_state:
		0: stop_music()
		1: play_music(music_menu_track)
		2: play_music(music_game_track)

func _on_music_finished():
	if music_player != null and music_player.stream != null and music_enabled: music_player.play()

func vibrate(ms: int):
	if not vibration_enabled: return
	if not (OS.has_feature("mobile") or OS.has_feature("web")): return
	Input.vibrate_handheld(max(ms, 50))

func vibrate_combo(streak: int):
	if not vibration_enabled: return
	if not (OS.has_feature("mobile") or OS.has_feature("web")): return
	var extra = int(field_density * 40.0)
	if streak < 5: Input.vibrate_handheld(50 + streak * 12 + extra)
	else: _do_combo_vibrate_async(streak + extra)

func _do_combo_vibrate_async(streak: int):
	Input.vibrate_handheld(45)
	await get_tree().create_timer(0.09).timeout
	Input.vibrate_handheld(60)
	if streak >= 10:
		await get_tree().create_timer(0.09).timeout
		Input.vibrate_handheld(95)

func update_layout():
	var vp = get_viewport_rect().size
	if vp.x <= 0 or vp.y <= 0: return
	ui_scale = min(vp.x / REF_SIZE.x, vp.y / REF_SIZE.y)
	layout_offset = (vp - REF_SIZE * ui_scale) / 2.0
	cell_size = CELL_SIZE_BASE * ui_scale
	grid_pos = to_screen(GRID_POS_BASE)
	_update_safe_area()
	_rebuild_bg_cache()
	queue_redraw()

func to_screen(p: Vector2) -> Vector2: return layout_offset + p * ui_scale
func to_screen_size(s: Vector2) -> Vector2: return s * ui_scale
func to_screen_rect(r: Rect2) -> Rect2: return Rect2(to_screen(r.position), to_screen_size(r.size))
func sw(width: float) -> float: return max(1.0, width * ui_scale)
func fs(size: int) -> int: return max(8, int(size * ui_scale))

func reset_grid():
	grid = []
	for y in range(GRID_SIZE):
		grid.append([])
		for x in range(GRID_SIZE): grid[y].append(null)

func get_touch_y_offset() -> float:
	if not OS.has_feature("mobile"): return 0.0
	return TOUCH_Y_OFFSET_BASE * ui_scale

func get_drag_origin_pixel() -> Vector2: return mouse_pos - drag_offset - Vector2(0, get_touch_y_offset())

func get_piece_tray_layout(i: int):
	var piece = pieces[i]
	if piece["blocks"].is_empty():
		return {"origin": Vector2.ZERO, "step": TRAY_BLOCK_STEP, "size": TRAY_BLOCK_SIZE, "bounds": Rect2()}
	var min_x = 999; var max_x = -999; var min_y = 999; var max_y = -999
	for b in piece["blocks"]:
		min_x = min(min_x, b.x); max_x = max(max_x, b.x)
		min_y = min(min_y, b.y); max_y = max(max_y, b.y)
	var blocks_w = max_x - min_x + 1
	var blocks_h = max_y - min_y + 1
	var max_dim = max(blocks_w * TRAY_BLOCK_STEP, blocks_h * TRAY_BLOCK_STEP)
	var fit_scale = 1.0
	if max_dim > MAX_TRAY_SIZE: fit_scale = MAX_TRAY_SIZE / max_dim
	var step = TRAY_BLOCK_STEP * fit_scale * ui_scale
	var size = TRAY_BLOCK_SIZE * fit_scale * ui_scale
	var center_slot = to_screen(TRAY_SLOT_CENTERS[i])
	var piece_center_offset = Vector2((min_x + max_x + 1) * 0.5 * step, (min_y + max_y + 1) * 0.5 * step)
	return {
		"origin": center_slot - piece_center_offset, "step": step, "size": size,
		"bounds": Rect2(center_slot - Vector2(MAX_TRAY_SIZE, MAX_TRAY_SIZE) * 0.5 * ui_scale,
			Vector2(MAX_TRAY_SIZE, MAX_TRAY_SIZE) * ui_scale)
	}

func _count_filled() -> int:
	var c = 0
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if grid[y][x] != null: c += 1
	return c

func _shape_index_of(piece: Dictionary) -> int:
	var blocks = piece["blocks"]
	for i in range(ALL_SHAPES.size()):
		if ALL_SHAPES[i] == blocks: return i
	return -1

func _pick_small_shape_idx() -> int:
	return SMALL_SHAPE_IDX[randi() % SMALL_SHAPE_IDX.size()]

func _pick_fresh_color() -> Color:
	var attempts = 0
	while attempts < 10:
		var c = COLOR_PALETTE[randi() % COLOR_PALETTE.size()]
		var same = 0
		for lc in _last_piece_colors:
			if lc == c: same += 1
		if same < 2: return c
		attempts += 1
	return COLOR_PALETTE[randi() % COLOR_PALETTE.size()]

# ============================================================================
# PARTICLES
# ============================================================================

var particles = []

func init_particles():
	particles.clear()
	if reduce_effects or quality == Quality.LOW: return
	var grid_w = GRID_SIZE * CELL_SIZE_BASE
	var grid_h = GRID_SIZE * CELL_SIZE_BASE
	for i in range(_particle_count()):
		particles.append({
			"x": GRID_POS_BASE.x + randf() * grid_w,
			"y": GRID_POS_BASE.y + randf() * grid_h,
			"speed": randf_range(8.0, 22.0),
			"size": randf_range(1.8, 4.0),
			"phase": randf_range(0.0, TAU),
			"hue": randf(),
		})

func update_particles(delta):
	var grid_w = GRID_SIZE * CELL_SIZE_BASE
	var grid_h = GRID_SIZE * CELL_SIZE_BASE
	for p in particles:
		p["y"] -= p["speed"] * delta
		p["phase"] += delta * 2.5
		if p["y"] < GRID_POS_BASE.y:
			p["y"] = GRID_POS_BASE.y + grid_h
			p["x"] = GRID_POS_BASE.x + randf() * grid_w

func draw_particles():
	for p in particles:
		var twinkle = 0.30 + 0.55 * (0.5 + 0.5 * sin(p["phase"]))
		var hue = p["hue"]
		var col: Color
		if hue < 0.45: col = N_CYAN
		elif hue < 0.72: col = N_MAGENTA
		elif hue < 0.88: col = N_PURPLE
		else: col = N_YELLOW
		var pos = to_screen(Vector2(p["x"], p["y"]))
		var sz = p["size"] * ui_scale
		draw_circle(pos, sz * 2.4, Color(col.r, col.g, col.b, twinkle * 0.20))
		draw_circle(pos, sz, Color(col.r, col.g, col.b, twinkle))
		draw_circle(pos, sz * 0.42, Color(1, 1, 1, twinkle * 0.9))

func spawn_effect_burst(world_pos: Vector2, color: Color, count: int = 8):
	if reduce_effects or quality == Quality.LOW: return
	count = _burst_count(count)
	for i in range(count):
		var dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		visual_effects.append({"pos": world_pos,
			"vel": dir * randf_range(120.0, 300.0) * ui_scale,
			"life": 0.5, "max_life": 0.5, "color": color,
			"size": randf_range(5.0, 10.0) * ui_scale})

func update_visual_effects(delta):
	for i in range(visual_effects.size() - 1, -1, -1):
		var fx = visual_effects[i]
		fx.life -= delta
		if fx.life <= 0: visual_effects.remove_at(i)
		else: fx.pos += fx.vel * delta

func draw_visual_effects():
	for fx in visual_effects:
		var alpha = clamp(fx.life / fx.max_life, 0.0, 1.0)
		var fade = alpha * alpha
		draw_circle(fx.pos, fx.size * fade * 2.0, Color(fx.color.r, fx.color.g, fx.color.b, alpha * 0.25))
		draw_circle(fx.pos, fx.size * fade, Color(fx.color.r, fx.color.g, fx.color.b, alpha))
		if fx.size > 6 * ui_scale:
			draw_circle(fx.pos, fx.size * fade * 0.4, Color(1, 1, 1, alpha * 0.8))

func spawn_explosion_ring(world_pos: Vector2, max_r: float):
	if reduce_effects or quality == Quality.LOW: return
	explosion_rings.append({"pos": world_pos, "timer": 0.4, "max": 0.4, "max_radius": max_r})

func update_explosion_rings(delta):
	for i in range(explosion_rings.size() - 1, -1, -1):
		explosion_rings[i].timer -= delta
		if explosion_rings[i].timer <= 0: explosion_rings.remove_at(i)

func draw_explosion_rings():
	for r in explosion_rings:
		var t = 1.0 - r.timer / r.max
		var eased = 1.0 - pow(1.0 - t, 2.5)
		var radius = r.max_radius * eased
		var alpha = clamp(1.0 - t, 0.0, 1.0)
		draw_arc(r.pos, radius, 0.0, TAU, 32, Color(1.0, 0.9, 0.4, alpha * 0.95), sw(7))
		if radius > 4: draw_arc(r.pos, radius * 0.7, 0.0, TAU, 24, Color(1.0, 0.5, 0.9, alpha * 0.75), sw(4))
		draw_circle(r.pos, radius * 0.6, Color(1.0, 0.8, 0.5, alpha * 0.22))

func update_drag_trail(delta):
	if dragging_piece == -1: drag_trail.clear(); return
	if reduce_effects or quality == Quality.LOW: return
	_drag_trail_timer += delta
	if _drag_trail_timer < 0.025: return
	_drag_trail_timer = 0.0
	var piece = pieces[dragging_piece]
	if piece["blocks"].is_empty(): return
	var origin = get_drag_origin_pixel()
	for block in piece["blocks"]:
		var pos = origin + Vector2(block) * cell_size + Vector2(cell_size, cell_size) * 0.5
		drag_trail.append({"pos": pos, "life": 0.35, "max_life": 0.35,
			"color": piece["color"], "size": cell_size * 0.35})
		if drag_trail.size() > 60: drag_trail.pop_front()

func update_drag_trail_particles(delta):
	for i in range(drag_trail.size() - 1, -1, -1):
		drag_trail[i].life -= delta
		if drag_trail[i].life <= 0: drag_trail.remove_at(i)

func draw_drag_trail():
	for p in drag_trail:
		var t = p.life / p.max_life
		draw_circle(p.pos, p.size * t * 1.5, Color(p.color.r, p.color.g, p.color.b, t * 0.20))
		draw_circle(p.pos, p.size * t, Color(p.color.r, p.color.g, p.color.b, t * 0.35))

func spawn_confetti():
	if reduce_effects or quality == Quality.LOW: return
	var vp = get_viewport_rect().size
	var count = _burst_count(80)
	for i in range(count):
		confetti.append({"pos": Vector2(randf_range(0, vp.x), -20),
			"vel": Vector2(randf_range(-150, 150), randf_range(80, 260)),
			"color": COLOR_PALETTE[randi() % COLOR_PALETTE.size()],
			"size": randf_range(6, 12) * ui_scale,
			"rot": randf_range(0, TAU), "rot_speed": randf_range(-6, 6),
			"life": 3.0, "max_life": 3.0})

func update_confetti(delta):
	for i in range(confetti.size() - 1, -1, -1):
		var c = confetti[i]
		c.life -= delta; c.vel.y += 200 * delta
		c.pos += c.vel * delta; c.rot += c.rot_speed * delta
		if c.life <= 0: confetti.remove_at(i)

func draw_confetti():
	for c in confetti:
		var alpha = clamp(c.life / c.max_life, 0.0, 1.0)
		var half = c.size / 2.0
		var cos_r = cos(c.rot); var sin_r = sin(c.rot)
		var pts = PackedVector2Array()
		for corner in [Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)]:
			pts.append(c.pos + Vector2(corner.x * cos_r - corner.y * sin_r, corner.x * sin_r + corner.y * cos_r))
		draw_colored_polygon(pts, Color(c.color.r, c.color.g, c.color.b, alpha))

func trigger_flash(a := 0.3):
	if reduce_effects: return
	flash_alpha = max(flash_alpha, a)
func update_flash(delta): flash_alpha = max(0.0, flash_alpha - delta * 2.5)

func draw_flash():
	if flash_alpha > 0.01:
		draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(1, 1, 1, flash_alpha))

func update_score_popups(delta):
	for i in range(score_popups.size() - 1, -1, -1):
		var p = score_popups[i]
		p.timer -= delta
		p.pos.y -= delta * 90.0 * ui_scale
		if p.timer <= 0: score_popups.remove_at(i)

func draw_score_popups():
	for p in score_popups:
		var a = clamp(p.timer / p.max, 0.0, 1.0)
		var fsz = int(fs(22) * (1.0 + (1.0 - a) * 0.4))
		draw_string(active_font(), p.pos - Vector2(80, -1 * ui_scale), p.text,
			HORIZONTAL_ALIGNMENT_CENTER, 160 * ui_scale, fsz, Color(0.05, 0.02, 0.15, a * 0.9))
		draw_string(active_font(), p.pos - Vector2(80, 0), p.text,
			HORIZONTAL_ALIGNMENT_CENTER, 160 * ui_scale, fsz, Color(p.color.r, p.color.g, p.color.b, a))

func update_row_glow(delta):
	for i in range(row_glow_cells.size() - 1, -1, -1):
		row_glow_cells[i].t -= delta
		if row_glow_cells[i].t <= 0: row_glow_cells.remove_at(i)

func draw_row_glow():
	if row_glow_cells.is_empty(): return
	var cur = get_shaked_grid_pos()
	for g in row_glow_cells:
		var a = g.t / g.max
		var pulse = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.008)
		var rect = Rect2(cur + Vector2(g.x, g.y) * cell_size,
			Vector2(cell_size - 3 * ui_scale, cell_size - 3 * ui_scale))
		draw_rect(rect, Color(1.0, 0.9, 0.3, a * 0.35 * pulse))
		draw_rect(rect, Color(1.0, 0.8, 0.2, a * 0.85 * pulse), false, sw(3))

# ============================================================================
# HINT
# ============================================================================

func _hint_score_move(piece_idx: int, sx: int, sy: int) -> float:
	var p = pieces[piece_idx]
	var placed := {}
	for b in p["blocks"]: placed[Vector2i(sx + b.x, sy + b.y)] = true
	var score_val = 0.0
	for y in range(GRID_SIZE):
		var fl = 0
		for x in range(GRID_SIZE):
			if grid[y][x] != null or placed.has(Vector2i(x, y)): fl += 1
		if fl == GRID_SIZE: score_val += 1000.0
		elif fl == GRID_SIZE - 1: score_val += 50.0
	for x in range(GRID_SIZE):
		var fl = 0
		for y in range(GRID_SIZE):
			if grid[y][x] != null or placed.has(Vector2i(x, y)): fl += 1
		if fl == GRID_SIZE: score_val += 1000.0
		elif fl == GRID_SIZE - 1: score_val += 50.0
	for b in p["blocks"]:
		var px = sx + b.x; var py = sy + b.y
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if dx == 0 and dy == 0: continue
				var nx = px + dx; var ny = py + dy
				if nx >= 0 and nx < GRID_SIZE and ny >= 0 and ny < GRID_SIZE:
					if grid[ny][nx] != null: score_val += 3.0
	return score_val

func _find_hint() -> Dictionary:
	var best := {}
	var best_score := -1.0
	for i in range(pieces.size()):
		var p = pieces[i]
		if p["blocks"].is_empty(): continue
		for y in range(GRID_SIZE):
			for x in range(GRID_SIZE):
				if can_place_piece(p["blocks"], x, y):
					var s = _hint_score_move(i, x, y)
					if s > best_score: best_score = s; best = {"idx": i, "x": x, "y": y}
	if not best.is_empty(): return best
	for i in range(pieces.size()):
		var p = pieces[i]
		if p["blocks"].is_empty(): continue
		for y in range(GRID_SIZE):
			for x in range(GRID_SIZE):
				if can_place_piece(p["blocks"], x, y): return {"idx": i, "x": x, "y": y}
	return {}

func _show_hint():
	hint_result = _find_hint()
	if not hint_result.is_empty():
		hint_visible = true; hint_timer = HINT_SHOW_DURATION

func update_hint(delta):
	if state != State.PLAYING: return
	if dragging_piece != -1:
		hint_timer = 0.0; hint_visible = false; return
	if hint_visible:
		hint_timer -= delta
		if hint_timer <= 0.0: hint_visible = false
		return
	hint_timer += delta
	if hint_timer >= HINT_IDLE_TIME:
		_show_hint(); hint_timer = 0.0

func draw_hint():
	if not hint_visible or hint_result.is_empty(): return
	var idx = int(hint_result.idx)
	if idx < 0 or idx >= pieces.size(): return
	var p = pieces[idx]
	if p == null or p["blocks"].is_empty(): return
	var cur = get_shaked_grid_pos()
	var pulse = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.008)
	var hx = int(hint_result.x); var hy = int(hint_result.y)
	for block in p["blocks"]:
		var gx = hx + block.x; var gy = hy + block.y
		var rect = Rect2(cur + Vector2(gx, gy) * cell_size,
			Vector2(cell_size - 3 * ui_scale, cell_size - 3 * ui_scale))
		draw_rect(rect, Color(0.4, 1.0, 0.7, 0.25 * pulse))
		draw_rect(rect, Color(0.5, 1.0, 0.8, 0.9 * pulse), false, sw(3))

# ============================================================================
# ACH SCROLL
# ============================================================================

var ach_scroll_px: float = 0.0
var ach_velocity: float = 0.0
var ach_dragging: bool = false
var ach_drag_start_y: float = 0.0
var ach_drag_start_scroll: float = 0.0
var ach_last_move_y: float = 0.0
var ach_last_move_time: float = 0.0

const ACH_CARD_H = 110.0
const ACH_CARD_GAP = 12.0
const ACH_TOP_Y = 340.0
const ACH_BOTTOM_Y = 1440.0

func _ach_max_scroll() -> float:
	var total = ACHIEVEMENTS.size() * (ACH_CARD_H + ACH_CARD_GAP) - ACH_CARD_GAP
	return max(0.0, total - (ACH_BOTTOM_Y - ACH_TOP_Y))

# ============================================================================
# BACKGROUND
# ============================================================================

func _rebuild_bg_cache():
	if reduce_effects: _bg_cache = null; return
	var vp = get_viewport_rect().size
	if vp.x <= 0 or vp.y <= 0: _bg_cache = null; return
	var w = 96
	var h = 192
	_bg_cache_size = Vector2i(w, h)
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		var t = float(y) / float(h - 1)
		var col: Color
		if t < 0.5: col = C_BG_TOP.lerp(C_BG_MID, t * 2.0)
		else: col = C_BG_MID.lerp(C_BG_BOT, (t - 0.5) * 2.0)
		img.fill_rect(Rect2i(0, y, w, 1), col)
	var cx = w * 0.5
	for y in range(h):
		var ty = float(y) / float(h - 1)
		var beam_strength = (1.0 - ty) * 0.55 + 0.15
		for x in range(w):
			var dx = abs(float(x) - cx) / (w * 0.5)
			var falloff = exp(-dx * dx * 6.0)
			var a = falloff * beam_strength * 0.35
			var base = img.get_pixel(x, y)
			img.set_pixel(x, y, Color(
				base.r * (1.0 - a) + 0.68 * a,
				base.g * (1.0 - a) + 0.32 * a,
				base.b * (1.0 - a) + 1.00 * a, 1.0))
	for sx in [0.18, 0.32, 0.68, 0.82]:
		var px = int(sx * w)
		for y in range(h):
			var ty = float(y) / float(h - 1)
			var a2 = (0.14 + 0.06 * sin(ty * 6.28)) * 0.9
			var base2 = img.get_pixel(px, y)
			img.set_pixel(px, y, Color(
				base2.r * (1.0 - a2) + 0.85 * a2,
				base2.g * (1.0 - a2) + 0.60 * a2,
				base2.b * (1.0 - a2) + 1.00 * a2, 1.0))
	_bg_cache = ImageTexture.create_from_image(img)

func _draw_cosmic_bg(vp: Vector2):
	if _bg_cache != null: draw_texture_rect(_bg_cache, Rect2(Vector2.ZERO, vp), false)
	else: draw_rect(Rect2(Vector2.ZERO, vp), C_BG_MID)
	if reduce_effects or quality != Quality.HIGH: return
	var t = Time.get_ticks_msec() * 0.001
	var beam_w = vp.x * 0.16
	var beam_x = vp.x * 0.5 - beam_w * 0.5
	var pulse = 0.55 + 0.45 * sin(t * 0.7)
	draw_rect(Rect2(beam_x, 0, beam_w, vp.y), Color(0.75, 0.35, 1.0, 0.05 * pulse))
	draw_rect(Rect2(beam_x + beam_w * 0.35, 0, beam_w * 0.3, vp.y), Color(1.0, 0.85, 1.0, 0.08 * pulse))
	draw_rect(Rect2(beam_x + beam_w * 0.46, 0, beam_w * 0.08, vp.y), Color(1.0, 1.0, 1.0, 0.16 * pulse))
	var lines = [0.18, 0.32, 0.68, 0.82]
	for i in range(lines.size()):
		var lx = lines[i] * vp.x
		var lp = 0.5 + 0.5 * sin(t * 0.9 + i * 1.3)
		draw_rect(Rect2(lx - 1.5 * ui_scale, 0, 3 * ui_scale, vp.y),
			Color(0.72, 0.40, 1.0, 0.10 + 0.05 * lp))

func _draw_center_burst(vp: Vector2):
	if reduce_effects or quality != Quality.HIGH: return
	var t = Time.get_ticks_msec() * 0.001
	var c = Vector2(vp.x / 2.0, vp.y * 0.24)
	var pulse = 0.85 + 0.15 * sin(t * 2.4)
	for i in range(6):
		draw_circle(c, (18 + i * 14) * ui_scale * pulse, Color(1.0, 0.65, 1.0, 0.12 - i * 0.015))
	draw_circle(c, 20 * ui_scale, Color(1, 1, 1, 0.55))
	draw_circle(c, 12 * ui_scale, Color(1, 1, 1, 0.85))
	var rays = 14
	for i in range(rays):
		var ang = i * TAU / rays + sin(t * 1.2) * 0.08
		var ray_len = (90 + 40 * sin(t * 3.0 + i * 0.9)) * ui_scale
		var p0 = c + Vector2(cos(ang), sin(ang)) * 30 * ui_scale
		var p1 = c + Vector2(cos(ang), sin(ang)) * ray_len
		var alpha = 0.30 + 0.25 * sin(t * 3.5 + i)
		var col = N_MAGENTA if i % 2 == 0 else N_CYAN
		draw_line(p0, p1, Color(col.r, col.g, col.b, alpha * 0.6), sw(2.5))

func _draw_float_cubes(vp: Vector2, count: int, base_alpha: float):
	if reduce_effects: return
	if quality == Quality.LOW: count = min(count, 2)
	elif quality == Quality.MEDIUM: count = min(count, 5)
	var t = Time.get_ticks_msec() * 0.001
	var slots = [
		{"x": 0.20, "y": 0.18, "size": 105.0, "color": Color("#2EC4FF"), "ph": 0.0, "rot": -0.35},
		{"x": 0.80, "y": 0.16, "size": 100.0, "color": Color("#9BFF3D"), "ph": 1.4, "rot":  0.42},
		{"x": 0.15, "y": 0.62, "size": 108.0, "color": Color("#2EC4FF"), "ph": 2.6, "rot":  0.28},
		{"x": 0.84, "y": 0.70, "size": 100.0, "color": Color("#FF9E2C"), "ph": 3.7, "rot": -0.30},
		{"x": 0.50, "y": 0.06, "size": 78.0,  "color": Color("#FF2FD0"), "ph": 5.1, "rot":  0.20},
		{"x": 0.06, "y": 0.86, "size": 82.0,  "color": Color("#B15CFF"), "ph": 6.2, "rot": -0.22},
		{"x": 0.94, "y": 0.40, "size": 70.0,  "color": Color("#FF5C7C"), "ph": 7.5, "rot":  0.36},
		{"x": 0.30, "y": 0.44, "size": 62.0,  "color": Color("#2EE6D6"), "ph": 8.8, "rot": -0.18},
	]
	for i in range(min(count, slots.size())):
		var s = slots[i]
		var px = s.x * vp.x + sin(t * 0.5 + s.ph) * 18 * ui_scale
		var py = s.y * vp.y + cos(t * 0.45 + s.ph) * 18 * ui_scale
		var rot = s.rot + sin(t * 0.6 + s.ph) * 0.08
		var sz = s.size * ui_scale
		var cos_r = cos(rot); var sin_r = sin(rot)
		var half = sz / 2.0
		var pts = PackedVector2Array()
		for corner in [Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)]:
			pts.append(Vector2(px, py) + Vector2(corner.x * cos_r - corner.y * sin_r, corner.x * sin_r + corner.y * cos_r))
		var col = s.color
		var alpha = base_alpha
		draw_circle(Vector2(px, py), sz * 0.95, Color(col.r, col.g, col.b, 0.12 * alpha))
		var shadow_pts = PackedVector2Array()
		for p in pts: shadow_pts.append(p + Vector2(0, 6 * ui_scale))
		draw_colored_polygon(shadow_pts, Color(col.r * 0.25, col.g * 0.25, col.b * 0.4, alpha))
		draw_colored_polygon(pts, Color(col.r, col.g, col.b, alpha))
		var inner_center = Vector2(px, py) + Vector2(0, sz * 0.22).rotated(rot)
		draw_circle(inner_center, sz * 0.30, Color(col.r * 0.6, col.g * 0.6, col.b * 0.7, alpha * 0.5))
		var gloss_pts = PackedVector2Array()
		var gw = sz * 0.34; var gh = sz * 0.16
		for corner in [Vector2(-gw, -gh), Vector2(gw, -gh), Vector2(gw, gh), Vector2(-gw, gh)]:
			var gx = corner.x * cos_r - corner.y * sin_r
			var gy = corner.x * sin_r + corner.y * cos_r
			gloss_pts.append(Vector2(px, py) + Vector2(gx - sz * 0.05, gy - sz * 0.22))
		draw_colored_polygon(gloss_pts, Color(1, 1, 1, 0.75 * alpha))
		var spec_pos = Vector2(px, py) + Vector2(-sz * 0.13, -sz * 0.24).rotated(rot)
		draw_circle(spec_pos, sz * 0.06, Color(1, 1, 1, 0.95 * alpha))

	if quality == Quality.LOW: return
	for i in range(20):
		var sx = fmod(t * 22.0 + i * 137.0, vp.x)
		var sy = fmod(t * 14.0 + i * 89.0, vp.y)
		var r = (1.5 + sin(t * 3.0 + i) * 1.2) * ui_scale
		var a = (0.5 + 0.5 * sin(t * 4.0 + i * 0.7)) * 0.7 * base_alpha
		var col2 = [N_CYAN, N_MAGENTA, N_PURPLE, N_YELLOW][i % 4]
		draw_circle(Vector2(sx, sy), r * 2.2, Color(col2.r, col2.g, col2.b, a * 0.25))
		draw_circle(Vector2(sx, sy), r, Color(col2.r, col2.g, col2.b, a))

# ============================================================================
# PROCESS
# ============================================================================

func _process(delta):
	match state:
		State.MENU, State.SKINS, State.ACHIEVEMENTS, State.MODE_SELECT, State.CAMPAIGN_MAP:
			update_music_for_state(1)
		State.SETTINGS:
			if settings_return_state != State.PAUSED: update_music_for_state(1)
		State.PLAYING, State.TUTORIAL: update_music_for_state(2)
		State.PAUSED, State.GAME_OVER, State.REVIVE: pass
		_: update_music_for_state(0)

	if state == State.MENU and _menu_enter_t < 1.0:
		_menu_enter_t = min(1.0, _menu_enter_t + delta / 0.6)

	if state == State.LOADING:
		loading_elapsed += delta
		_update_menu_blocks(delta)
		var raw_t = clamp(loading_elapsed / LOADING_MIN_TIME, 0.0, 1.0)
		loading_progress = 1.0 - pow(1.0 - raw_t, 1.8)
		if loading_elapsed >= LOADING_MIN_TIME: loading_progress = 1.0; loading_ready = true
		if loading_ready and loading_elapsed >= LOADING_MIN_TIME + 0.35:
			if FileAccess.file_exists(TUTORIAL_SAVE): state = State.MENU; _menu_enter_t = 0.0
			else:
				start_classic_game(); state = State.TUTORIAL; tutorial_step = 0; tutorial_for_mode = 0
			loading_ready = false
		queue_redraw(); return

	if state == State.MENU:
		_update_menu_blocks(delta); _update_shake(delta)
		update_flash(delta); update_confetti(delta)
		queue_redraw(); return

	if state == State.REVIVE:
		if not revive_shown:
			revive_delay_timer = max(0.0, revive_delay_timer - delta)
			if revive_delay_timer <= 0.0:
				revive_shown = true; vibrate(60)
			queue_redraw(); return
		if revive_appear < 1.0:
			revive_appear = min(1.0, revive_appear + delta / REVIVE_APPEAR_DUR)
		if revive_dim < 1.0:
			revive_dim = min(1.0, revive_dim + delta / REVIVE_DIM_DUR)
		if revive_appear >= 1.0:
			revive_timer = max(0.0, revive_timer - delta)
			var secs = int(ceil(revive_timer))
			if secs != revive_last_tick_sec:
				revive_last_tick_sec = secs
				if secs > 0: play_sfx(sfx_button, 1.5)
			if revive_timer <= 0.0: revive_decline(); return
		queue_redraw(); return

	if state == State.ACHIEVEMENTS and not ach_dragging and absf(ach_velocity) > 1.0:
		ach_scroll_px = clamp(ach_scroll_px + ach_velocity * delta, 0.0, _ach_max_scroll())
		ach_velocity *= pow(0.04, delta)
		if absf(ach_velocity) < 10.0: ach_velocity = 0.0
		queue_redraw(); return

	if state == State.PLAYING and game_mode == GameMode.TIME:
		time_left -= delta
		if time_left <= 0.0: time_left = 0.0; end_time_game()
		queue_redraw()

	if shift_in_progress:
		shift_warning_timer -= delta
		if shift_warning_timer <= 0.0:
			shift_warning_count -= 1
			if shift_warning_count > 0:
				shift_warning_timer = SHIFT_WARN_DURATION
				play_sfx(sfx_button, 1.2 + (3 - shift_warning_count) * 0.15)
				vibrate(30)
			else:
				_apply_shift()
				shift_in_progress = false
				_check_shift_gameover()
		queue_redraw()

	if state == State.GAME_OVER and _go_scatter_timer > 0.0:
		_go_scatter_timer = max(0.0, _go_scatter_timer - delta)
		queue_redraw()

	_update_shake(delta); update_flash(delta); update_confetti(delta)
	update_score_popups(delta); update_row_glow(delta); update_hint(delta)
	_density_pulse += delta
	if dragging_piece != -1: update_drag_trail(delta)
	update_drag_trail_particles(delta)
	for i in range(_piece_spawn_delay.size()):
		if _piece_spawn_delay[i] > 0.0:
			_piece_spawn_delay[i] = max(0.0, _piece_spawn_delay[i] - delta)

	var score_animating = absf(displayed_score - float(score)) > 0.5
	var pieces_animating = false
	for t in piece_spawn_timers:
		if t > 0.0: pieces_animating = true; break
	for d in _piece_spawn_delay:
		if d > 0.0: pieces_animating = true; break
	var particles_animating = (state == State.PLAYING or state == State.TUTORIAL) and not reduce_effects
	var has_effects = not pop_cells.is_empty() or not flash_cells.is_empty() \
		or not combo_popups.is_empty() or not visual_effects.is_empty() \
		or not explosion_rings.is_empty() or not drag_trail.is_empty() \
		or not score_popups.is_empty() or not row_glow_cells.is_empty() or hint_visible
	var dragging = dragging_piece != -1
	if not has_effects and not score_animating and not pieces_animating \
			and not particles_animating and screen_shake <= 0.0 and not dragging \
			and flash_alpha <= 0.01 and confetti.is_empty() and field_density < DENSITY_WARN:
		return
	if particles_animating: update_particles(delta)
	if has_effects:
		update_visual_effects(delta); update_explosion_rings(delta)
		for i in range(pop_cells.size() - 1, -1, -1):
			pop_cells[i].timer -= delta
			if pop_cells[i].timer <= 0: pop_cells.remove_at(i)
		for i in range(flash_cells.size() - 1, -1, -1):
			flash_cells[i].timer -= delta
			if flash_cells[i].timer <= 0: flash_cells.remove_at(i)
		for i in range(combo_popups.size() - 1, -1, -1):
			combo_popups[i].timer -= delta
			if combo_popups[i].timer <= 0: combo_popups.remove_at(i)
	if score_animating:
		displayed_score = lerp(displayed_score, float(score), min(1.0, delta * SCORE_ANIM_SPEED))
		if absf(displayed_score - float(score)) <= 0.5: displayed_score = float(score)
	for i in range(piece_spawn_timers.size()):
		if piece_spawn_timers[i] > 0.0: piece_spawn_timers[i] = max(0.0, piece_spawn_timers[i] - delta)
	queue_redraw()

# ============================================================================
# DRAW ROUTER
# ============================================================================

func _draw():
	match state:
		State.LOADING: draw_loading_screen()
		State.TUTORIAL: draw_game_screen(); draw_tutorial_overlay()
		State.MENU: draw_menu()
		State.MODE_SELECT: draw_mode_select()
		State.SKINS: draw_skins_screen()
		State.ACHIEVEMENTS: draw_achievements_screen()
		State.CAMPAIGN_MAP: draw_campaign_screen()
		State.PLAYING: draw_game_screen()
		State.PAUSED: draw_game_screen(); draw_pause_overlay()
		State.GAME_OVER: draw_game_screen(); draw_game_over()
		State.REVIVE: draw_game_screen(); draw_revive_overlay()
		State.SETTINGS: draw_settings_screen()

# ============================================================================
# GAMEPLAY SCREEN
# ============================================================================

func draw_game_screen():
	var vp = get_viewport_rect().size
	_draw_cosmic_bg(vp)
	_draw_float_cubes(vp, 6, 0.45)
	draw_density_bar()
	draw_grid()
	draw_row_glow()
	draw_particles()
	draw_tray_slots()
	draw_hint()
	draw_drag_trail()
	draw_drag_highlight()
	draw_pieces()
	draw_explosion_rings()
	draw_visual_effects()
	draw_score_popups()
	draw_combo_popups()
	draw_confetti()
	draw_shift_warning()
	draw_hud()
	draw_flash()

func draw_density_bar():
	var cur = get_shaked_grid_pos()
	var bar_x = cur.x - 22 * ui_scale
	var bar_y = cur.y
	var bar_w = 10 * ui_scale
	var bar_h = GRID_SIZE * cell_size
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.02, 0.15, 0.85)
	bg.set_corner_radius_all(int(bar_w / 2.0))
	draw_style_box(bg, Rect2(bar_x, bar_y, bar_w, bar_h))
	var fill_h = bar_h * field_density
	var fill_y = bar_y + (bar_h - fill_h)
	var bar_col: Color
	if field_density < 0.40: bar_col = N_GREEN
	elif field_density < 0.65: bar_col = N_YELLOW
	elif field_density < 0.80: bar_col = N_ORANGE
	else: bar_col = N_RED
	var fill = StyleBoxFlat.new()
	fill.bg_color = bar_col
	fill.set_corner_radius_all(int(bar_w / 2.0))
	draw_style_box(fill, Rect2(bar_x, fill_y, bar_w, fill_h))
	if field_density > 0.05:
		draw_circle(Vector2(bar_x + bar_w / 2.0, fill_y), bar_w * 1.5, Color(bar_col.r, bar_col.g, bar_col.b, 0.35))
	if field_density >= DENSITY_WARN:
		var pulse = 0.5 + 0.5 * sin(_density_pulse * 6.0)
		draw_rect(Rect2(bar_x - 2 * ui_scale, bar_y - 2 * ui_scale,
			bar_w + 4 * ui_scale, bar_h + 4 * ui_scale),
			Color(N_RED.r, N_RED.g, N_RED.b, 0.45 * pulse), false, sw(2))

func draw_grid():
	var cur = get_shaked_grid_pos()
	var outer = Rect2(cur - Vector2(16, 16) * ui_scale,
		Vector2(GRID_SIZE * cell_size, GRID_SIZE * cell_size) + Vector2(32, 32) * ui_scale)
	if field_density >= DENSITY_WARN and not reduce_effects:
		var pulse = 0.5 + 0.5 * sin(_density_pulse * 5.0)
		for i in range(3):
			var grow = (i + 1) * 6 * ui_scale
			var gs = StyleBoxFlat.new()
			gs.bg_color = Color(N_RED.r, N_RED.g, N_RED.b, (0.20 - i * 0.05) * pulse)
			gs.set_corner_radius_all(int(24 * ui_scale) + int(grow))
			draw_style_box(gs, Rect2(outer.position - Vector2(grow, grow),
				outer.size + Vector2(grow * 2, grow * 2)))
	if not reduce_effects and quality != Quality.LOW:
		for i in range(4):
			var grow = (i + 1) * 5 * ui_scale
			var gs = StyleBoxFlat.new()
			gs.bg_color = Color(0.35, 0.55, 1.0, 0.18 - i * 0.035)
			gs.set_corner_radius_all(int(24 * ui_scale) + int(grow))
			draw_style_box(gs, Rect2(outer.position - Vector2(grow, grow),
				outer.size + Vector2(grow * 2, grow * 2)))
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.02, 0.16)
	bg.set_corner_radius_all(int(24 * ui_scale))
	bg.border_width_top = int(3 * ui_scale); bg.border_width_bottom = int(3 * ui_scale)
	bg.border_width_left = int(3 * ui_scale); bg.border_width_right = int(3 * ui_scale)
	bg.border_color = C_BORDER
	draw_style_box(bg, outer)
	var hl = StyleBoxFlat.new()
	hl.bg_color = Color(0.55, 0.35, 1.0, 0.10)
	hl.corner_radius_top_left = int(22 * ui_scale)
	hl.corner_radius_top_right = int(22 * ui_scale)
	draw_style_box(hl, Rect2(outer.position + Vector2(3, 3) * ui_scale,
		Vector2(outer.size.x - 6 * ui_scale, outer.size.y * 0.15)))
	var cell_radius = int(cell_size * 0.18)
	var almost_any = false
	for y in range(GRID_SIZE):
		var fl = 0
		for x in range(GRID_SIZE):
			if grid[y][x] != null: fl += 1
		if fl >= GRID_SIZE - 1: almost_any = true; break
	if not almost_any:
		for x in range(GRID_SIZE):
			var fl = 0
			for y in range(GRID_SIZE):
				if grid[y][x] != null: fl += 1
			if fl >= GRID_SIZE - 1: almost_any = true; break
	if almost_any:
		var ap = 0.5 + 0.5 * sin(_density_pulse * 6.0)
		draw_rect(outer, Color(N_YELLOW.r, N_YELLOW.g, N_YELLOW.b, 0.5 * ap), false, sw(4))
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var pos = cur + Vector2(x, y) * cell_size
			var base_size = Vector2(cell_size - 5 * ui_scale, cell_size - 5 * ui_scale)
			var rect = Rect2(pos + Vector2(2.5, 2.5) * ui_scale, base_size)
			var pop = get_pop_cell(x, y)
			if pop != null:
				var progress = 1.0 - (pop.timer / pop.max)
				var pop_scale = lerp(0.25, 1.15, ease(progress, 0.25)) * (1.0 - ease(progress, 3.0) * 0.15)
				var size = base_size * pop_scale
				if pop.get("squash", false):
					var e = ease(progress, 2.5)
					size = Vector2(base_size.x * lerp(1.35, 1.0, e), base_size.y * lerp(0.65, 1.0, e))
				rect = Rect2(pos + Vector2(2.5, 2.5) * ui_scale + (base_size - size) / 2.0, size)
			var cell_color = grid[y][x]
			if cell_color != null:
				draw_beveled_block(rect, cell_color)
			else:
				var empty = StyleBoxFlat.new()
				empty.bg_color = Color(0.08, 0.04, 0.20)
				empty.set_corner_radius_all(cell_radius)
				empty.border_width_top = int(1.5 * ui_scale)
				empty.border_width_bottom = int(0.5 * ui_scale)
				empty.border_width_left = int(1.0 * ui_scale)
				empty.border_width_right = int(1.0 * ui_scale)
				empty.border_color = Color(0.35, 0.22, 0.62, 0.75)
				draw_style_box(empty, rect)
			var flash = get_flash_cell(x, y)
			if flash != null:
				var fa = flash.timer / flash.max
				draw_rect(Rect2(pos, base_size), Color(1, 1, 1, fa * 0.9))
				draw_rect(Rect2(pos, base_size), Color(1.0, 0.9, 0.4, fa * 0.6), false, sw(3))

func get_pop_cell(x, y):
	for p in pop_cells:
		if p.x == x and p.y == y: return p
	return null

func get_flash_cell(x, y):
	for f in flash_cells:
		if f.x == x and f.y == y: return f
	return null

func draw_special_icon(rect, type):
	var center = rect.position + rect.size / 2.0
	var r = rect.size.x * 0.32
	var now_ms = Time.get_ticks_msec()
	if type == "bomb":
		draw_circle(center + Vector2(0, r * 0.15), r * 1.02, Color(0, 0, 0, 0.35))
		draw_circle(center, r, Color(0.10, 0.06, 0.16))
		draw_arc(center, r, 0, TAU, 32, Color(0.7, 0.35, 1.0), sw(2))
		draw_circle(center + Vector2(-r * 0.35, -r * 0.35), r * 0.30, Color(1, 1, 1, 0.45))
		draw_circle(center + Vector2(-r * 0.42, -r * 0.42), r * 0.12, Color(1, 1, 1, 0.9))
		var fa = center + Vector2(r * 0.30, -r * 0.85)
		var fb = center + Vector2(r * 0.55, -r * 1.15)
		var fc = center + Vector2(r * 0.45, -r * 1.45)
		draw_line(fa, fb, Color(0.40, 0.25, 0.10), sw(4))
		draw_line(fb, fc, Color(0.40, 0.25, 0.10), sw(3))
		var pulse = 0.75 + 0.25 * sin(now_ms * 0.018)
		draw_circle(fc, r * 0.35 * pulse, Color(1.0, 0.5, 1.0, 0.5))
		draw_circle(fc, r * 0.25 * pulse, Color(1.0, 0.75, 1.0, 0.85))
		draw_circle(fc, r * 0.12, Color(1.0, 0.98, 1.0))
	elif type == "line_clear":
		var al = r * 0.90; var ah = r * 0.42
		var th = sw(4); var gh = sw(8)
		var pulse2 = 0.55 + 0.25 * sin(now_ms * 0.008)
		var cg = Color(1.0, 0.35, 0.95, pulse2)
		draw_line(center + Vector2(-al, 0), center + Vector2(al, 0), cg, gh)
		draw_line(center + Vector2(0, -al), center + Vector2(0, al), cg, gh)
		draw_line(center + Vector2(-al, 0), center + Vector2(al, 0), Color.WHITE, th)
		draw_line(center + Vector2(0, -al), center + Vector2(0, al), Color.WHITE, th)
		draw_line(center + Vector2(al, 0), center + Vector2(al - ah, -ah), Color.WHITE, th)
		draw_line(center + Vector2(al, 0), center + Vector2(al - ah, ah), Color.WHITE, th)
		draw_line(center + Vector2(-al, 0), center + Vector2(-al + ah, -ah), Color.WHITE, th)
		draw_line(center + Vector2(-al, 0), center + Vector2(-al + ah, ah), Color.WHITE, th)
		draw_circle(center, r * 0.28, Color(1.0, 0.35, 0.95, 0.9))
		draw_circle(center, r * 0.18, Color.WHITE)

func draw_tray_slots():
	for i in range(3):
		if i == dragging_piece: continue
		var p = pieces[i]
		if p["blocks"].is_empty(): continue
		var slot = to_screen(TRAY_SLOT_CENTERS[i])
		var slot_rect = Rect2(slot - Vector2(125, 100) * ui_scale, Vector2(250, 200) * ui_scale)
		var s = StyleBoxFlat.new()
		s.bg_color = Color(0.06, 0.02, 0.18, 0.85)
		s.set_corner_radius_all(int(22 * ui_scale))
		s.border_width_top = int(1.5 * ui_scale); s.border_width_bottom = int(1.5 * ui_scale)
		s.border_width_left = int(1.5 * ui_scale); s.border_width_right = int(1.5 * ui_scale)
		s.border_color = Color(0.35, 0.22, 0.62, 0.65)
		draw_style_box(s, slot_rect)

func draw_pieces():
	if _piece_has_spot_dirty: _recalc_pieces_has_spot()
	for i in range(pieces.size()):
		var piece = pieces[i]
		if piece["blocks"].is_empty() or i == dragging_piece: continue
		if i < _piece_spawn_delay.size() and _piece_spawn_delay[i] > 0.0: continue
		var layout = get_piece_tray_layout(i)
		var origin = layout["origin"]; var block_step = layout["step"]; var base_size = layout["size"]
		var t = 1.0
		if i < piece_spawn_timers.size() and piece_spawn_timers[i] > 0.0:
			t = 1.0 - piece_spawn_timers[i] / PIECE_SPAWN_DURATION
			var t2 = t - 1.0
			t = t2 * t2 * ((1.6 + 1.0) * t2 + 1.6) + 1.0
		var spawn_scale = clamp(t, 0.1, 1.3)
		var spawn_alpha = clamp(t * 1.6, 0.0, 1.0)
		var block_size = Vector2(base_size, base_size) * spawn_scale
		var y_slide = (1.0 - clamp(t, 0.0, 1.0)) * -90.0 * ui_scale
		var no_spot = i < _piece_has_spot_cache.size() and not _piece_has_spot_cache[i]
		for block in piece["blocks"]:
			var bc = origin + Vector2(block) * block_step + Vector2(base_size, base_size) * 0.5 + Vector2(0, y_slide)
			var pos = bc - block_size * 0.5
			var rect = Rect2(pos, block_size)
			var color = piece["color"]
			if no_spot: color = Color(color.r, color.g, color.b, color.a * 0.35)
			color.a *= spawn_alpha
			draw_beveled_block(rect, color)
			if t > 0.85:
				if no_spot: draw_rect(rect, Color(1.0, 0.3, 0.5, 0.8), false, sw(2))
				else: draw_special_icon(rect, piece["type"])

func draw_drag_highlight():
	if dragging_piece == -1: return
	var piece = pieces[dragging_piece]
	if piece["blocks"].is_empty(): return
	var origin_pixel = get_drag_origin_pixel()
	var cur = get_shaked_grid_pos()
	var grid_offset = origin_pixel - cur
	var sx = round(grid_offset.x / cell_size); var sy = round(grid_offset.y / cell_size)
	var valid = can_place_piece(piece["blocks"], sx, sy)
	if valid:
		var piece_cells := {}
		for block in piece["blocks"]: piece_cells[Vector2i(sx + block.x, sy + block.y)] = true
		var wcr := {}; var wcc := {}
		for block in piece["blocks"]:
			var gx = sx + block.x; var gy = sy + block.y
			if not wcr.has(gy):
				var rf = true
				for cx in range(GRID_SIZE):
					if grid[gy][cx] == null and not piece_cells.has(Vector2i(cx, gy)): rf = false; break
				if rf: wcr[gy] = true
			if not wcc.has(gx):
				var cf = true
				for cy in range(GRID_SIZE):
					if grid[cy][gx] == null and not piece_cells.has(Vector2i(gx, cy)): cf = false; break
				if cf: wcc[gx] = true
		var pulse = 0.32 + 0.16 * sin(Time.get_ticks_msec() * 0.012)
		for y in wcr.keys():
			draw_rect(Rect2(cur + Vector2(0, y) * cell_size, Vector2(GRID_SIZE * cell_size, cell_size)),
				Color(1.0, 0.4, 1.0, pulse))
		for x in wcc.keys():
			draw_rect(Rect2(cur + Vector2(x, 0) * cell_size, Vector2(cell_size, GRID_SIZE * cell_size)),
				Color(1.0, 0.4, 1.0, pulse))
		for block in piece["blocks"]:
			var gx = sx + block.x; var gy = sy + block.y
			var gr = Rect2(cur + Vector2(gx, gy) * cell_size,
				Vector2(cell_size - 3 * ui_scale, cell_size - 3 * ui_scale))
			draw_rect(gr, Color(1, 1, 1, 0.35))
			draw_rect(gr, Color(1, 1, 1, 0.85), false, sw(3))
	for block in piece["blocks"]:
		var pos = origin_pixel + Vector2(block) * cell_size
		var rect = Rect2(pos, Vector2(cell_size - 3 * ui_scale, cell_size - 3 * ui_scale))
		draw_beveled_block(rect, piece["color"])
		draw_special_icon(rect, piece["type"])

func draw_combo_popups():
	for p in combo_popups:
		var alpha = clamp(p.timer / p.max, 0.0, 1.0)
		var elapsed = p.max - p.timer
		var bounce = 1.0
		if elapsed < 0.25: bounce = 1.0 + 0.55 * (1.0 - elapsed / 0.25)
		var rise = (1.0 - alpha) * 60.0 * ui_scale
		var fsz = int(fs(36) * bounce)
		var pos = p.pos - Vector2(200 * ui_scale, rise)
		for i in range(3, 0, -1):
			draw_string(active_font(), pos + Vector2(0, i * ui_scale),
				p.text, HORIZONTAL_ALIGNMENT_CENTER, 400 * ui_scale, fsz, Color(0.10, 0.02, 0.30, alpha * 0.75))
		draw_string(active_font(), pos - Vector2(0, 2 * ui_scale),
			p.text, HORIZONTAL_ALIGNMENT_CENTER, 400 * ui_scale, fsz, Color(1.0, 0.75, 0.2, alpha * 0.6))
		draw_string(active_font(), pos, p.text,
			HORIZONTAL_ALIGNMENT_CENTER, 400 * ui_scale, fsz, Color(1.0, 0.95, 1.0, alpha))

func draw_shift_warning():
	if not shift_in_progress: return
	var vp = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.05, 0.0, 0.15, 0.45))
	var t_ms = Time.get_ticks_msec()
	var pulse = 0.85 + 0.15 * sin(t_ms * 0.025)
	var text = "SHIFT IN %d" % shift_warning_count
	var cy = vp.y * 0.42
	var tfs = int(fs(78) * pulse)
	for i in range(4):
		var off = i * 2 * ui_scale
		draw_string(active_font(), Vector2(0, cy - off), text,
			HORIZONTAL_ALIGNMENT_CENTER, vp.x, tfs,
			Color(1.0, 0.25, 0.55, (0.55 - i * 0.12)))
	draw_string(active_font(), Vector2(0, cy), text,
		HORIZONTAL_ALIGNMENT_CENTER, vp.x, tfs, Color(1, 1, 1))
	var dir_names = ["◄  LEFT", "RIGHT  ►", "▲  UP", "DOWN  ▼"]
	var dir_col = [N_CYAN, N_MAGENTA, N_GREEN, N_ORANGE][shift_direction]
	draw_string(active_font(), Vector2(0, cy + fs(90)),
		dir_names[shift_direction], HORIZONTAL_ALIGNMENT_CENTER, vp.x,
		fs(36), dir_col)
	var arrow_c = Vector2(vp.x / 2.0, cy + fs(180))
	var arrow_col = dir_col
	var rot = [PI, 0.0, PI * 0.5, -PI * 0.5][shift_direction]
	var arrow_size = 30 * ui_scale
	var cos_r = cos(rot); var sin_r = sin(rot)
	var pts = PackedVector2Array()
	for corner in [Vector2(-0.6, -0.5), Vector2(0.4, -0.5), Vector2(0.4, -0.15),
				   Vector2(0.9, 0.0), Vector2(0.4, 0.15), Vector2(0.4, 0.5),
				   Vector2(-0.6, 0.5)]:
		var v = corner * arrow_size
		pts.append(arrow_c + Vector2(v.x * cos_r - v.y * sin_r, v.x * sin_r + v.y * cos_r))
	draw_colored_polygon(pts, arrow_col)
	var badge_rect = to_screen_rect(Rect2(0, 20, REF_SIZE.x, 40))
	draw_string(active_font(), badge_rect.position,
		"SHIFT MODE ACTIVE", HORIZONTAL_ALIGNMENT_CENTER,
		to_screen_size(Vector2(REF_SIZE.x, 0)).x, fs(16),
		Color(1.0, 0.6, 0.9, 0.8))

func draw_hud():
	var vp = get_viewport_rect().size
	var top_inset = _safe_insets.y
	var left_inset = _safe_insets.x
	var right_inset = _safe_insets.z
	var pr = Rect2(left_inset + 22 * ui_scale, top_inset + 40 * ui_scale, 76 * ui_scale, 76 * ui_scale)
	_draw_panel(pr, C_PANEL, 20, C_BORDER)
	_draw_icon_pause(pr.position + pr.size / 2.0, 20 * ui_scale, Color(0.9, 0.85, 1.0))
	var hb = Rect2(vp.x - right_inset - 190 * ui_scale, top_inset + 40 * ui_scale, 76 * ui_scale, 76 * ui_scale)
	_draw_panel(hb, C_PANEL, 20, C_BORDER)
	_draw_icon_lightbulb(hb.position + hb.size / 2.0, 20 * ui_scale, Color(1.0, 0.92, 0.45))
	hint_btn_rect = hb
	var gr = Rect2(vp.x - right_inset - 98 * ui_scale, top_inset + 40 * ui_scale, 76 * ui_scale, 76 * ui_scale)
	_draw_panel(gr, C_PANEL, 20, C_BORDER)
	_draw_icon_gear(gr.position + gr.size / 2.0, 20 * ui_scale, Color(0.9, 0.85, 1.0))
	var bc = vp.x / 2.0
	var rec_text = str(high_score)
	if game_mode == GameMode.TIME: rec_text = str(time_high)
	_draw_icon_crown(Vector2(bc - 70 * ui_scale, top_inset + 60 * ui_scale), 14 * ui_scale, N_YELLOW)
	draw_string(active_font(), Vector2(0, top_inset + 68 * ui_scale), rec_text,
		HORIZONTAL_ALIGNMENT_CENTER, vp.x, fs(26), Color(1.0, 0.88, 0.30))
	var score_panel = Rect2(bc - 180 * ui_scale, top_inset + 90 * ui_scale, 360 * ui_scale, 100 * ui_scale)
	_draw_panel(score_panel, Color(0.08, 0.03, 0.22, 0.75), 22, Color(0.55, 0.35, 1.0, 0.55))
	var score_pulse = 1.0
	if absf(displayed_score - score) > 0.5: score_pulse = 1.0 + 0.10 * sin(Time.get_ticks_msec() * 0.010)
	draw_string(active_font(), Vector2(0, top_inset + 152 * ui_scale + 3 * ui_scale),
		str(int(round(displayed_score))), HORIZONTAL_ALIGNMENT_CENTER, vp.x, int(fs(66) * score_pulse),
		Color(0.10, 0.02, 0.30, 0.9))
	draw_string(active_font(), Vector2(0, top_inset + 152 * ui_scale),
		str(int(round(displayed_score))), HORIZONTAL_ALIGNMENT_CENTER, vp.x, int(fs(66) * score_pulse),
		Color(1.0, 0.98, 1.0))
	var shift_pct = float(cleared_lines_total) / float(max(1, shift_lines_required))
	shift_pct = clamp(shift_pct, 0.0, 1.0)
	var sp_w = 240 * ui_scale
	var sp_h = 8 * ui_scale
	var sp_x = (vp.x - sp_w) / 2.0
	var sp_y = top_inset + 210 * ui_scale
	_draw_panel(Rect2(sp_x, sp_y, sp_w, sp_h), Color(0.08, 0.03, 0.18, 0.85),
		sp_h / 2.0, Color(0.55, 0.25, 0.7, 0.6))
	if shift_pct > 0:
		var sfill = StyleBoxFlat.new()
		sfill.bg_color = N_MAGENTA
		sfill.set_corner_radius_all(int(sp_h / 2.0))
		draw_style_box(sfill, Rect2(sp_x, sp_y, sp_w * shift_pct, sp_h))
	draw_string(active_font(), Vector2(0, sp_y + sp_h + 16 * ui_scale),
		"SHIFT: %d/%d" % [cleared_lines_total % max(1, shift_lines_required), shift_lines_required],
		HORIZONTAL_ALIGNMENT_CENTER, vp.x, fs(14), Color(1.0, 0.7, 1.0, 0.8))
	if game_mode == GameMode.TIME:
		var secs = int(ceil(time_left))
		var tcol = N_CYAN
		var tbg = Color(0.10, 0.04, 0.24, 0.92)
		var tborder = N_CYAN
		if secs <= 10: tcol = Color(1, 0.42, 0.55); tbg = Color(0.35, 0.06, 0.18, 0.95); tborder = Color(1, 0.4, 0.55)
		elif secs <= 20: tcol = N_YELLOW; tbg = Color(0.30, 0.15, 0.05, 0.95); tborder = N_ORANGE
		var tr = to_screen_rect(Rect2(300, 240, 300, 60))
		_draw_panel(tr, tbg, 30, tborder)
		var tc = tr.position + Vector2(60 * ui_scale, tr.size.y / 2.0)
		_draw_icon_clock(tc, 12 * ui_scale, tcol)
		draw_string(active_font(), tr.position + Vector2(85 * ui_scale, tr.size.y * 0.68),
			"%d %s" % [secs, tr_("time")], HORIZONTAL_ALIGNMENT_LEFT, -1, fs(30), tcol)
	if combo_streak > 1:
		var pulse = 0.8 + 0.2 * sin(Time.get_ticks_msec() * 0.012)
		var combo_col = Color(1, 0.6, 1.0, pulse)
		if combo_streak >= 10: combo_col = Color(1, 0.4, 0.4, pulse)
		elif combo_streak >= 5: combo_col = Color(1, 0.75, 0.2, pulse)
		var mult = min(1.0 + (combo_streak - 1) * 0.5, 5.0)
		var cb_rect = to_screen_rect(Rect2(600, 240, 280, 70))
		_draw_panel(cb_rect, Color(0.35, 0.05, 0.30, 0.78), 20, combo_col)
		draw_string(active_font(), Vector2(cb_rect.position.x, cb_rect.position.y + 34 * ui_scale),
			"COMBO x%d" % combo_streak, HORIZONTAL_ALIGNMENT_CENTER, cb_rect.size.x, fs(24), combo_col)
		var mult_text = "MAX" if mult >= 5.0 else ("x%.1f" % mult)
		draw_string(active_font(), Vector2(cb_rect.position.x, cb_rect.position.y + 60 * ui_scale),
			mult_text, HORIZONTAL_ALIGNMENT_CENTER, cb_rect.size.x, fs(20), Color(1.0, 0.95, 0.6, pulse))

# ============================================================================
# REVIVE OVERLAY
# ============================================================================

func draw_revive_overlay():
	var vp = get_viewport_rect().size
	var dim_alpha = 0.15 + 0.40 * revive_dim
	if not revive_shown: dim_alpha = 0.25
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.02, 0.01, 0.08, dim_alpha))
	if not revive_shown: return
	var ease_t = ease(revive_appear, 0.4)
	var panel_alpha = ease_t
	var panel_scale = 0.85 + 0.15 * ease_t
	var pw = min(vp.x * 0.88, 620 * ui_scale) * panel_scale
	var ph = min(vp.y * 0.62, 500 * ui_scale) * panel_scale
	var px = (vp.x - pw) / 2.0
	var py = (vp.y - ph) / 2.0
	var pr = Rect2(px, py, pw, ph)
	if not reduce_effects: _draw_glow(pr, N_MAGENTA, 5, 7.0, 0.22 * panel_alpha)
	var panel = StyleBoxFlat.new()
	panel.bg_color = Color(0.09, 0.04, 0.22, 0.97 * panel_alpha)
	panel.set_corner_radius_all(int(34 * ui_scale))
	panel.border_width_top = int(2.5 * ui_scale); panel.border_width_bottom = int(2.5 * ui_scale)
	panel.border_width_left = int(2.5 * ui_scale); panel.border_width_right = int(2.5 * ui_scale)
	panel.border_color = Color(C_BORDER_HI.r, C_BORDER_HI.g, C_BORDER_HI.b, panel_alpha)
	draw_style_box(panel, pr)
	_draw_icon_video(Vector2(px + pw / 2.0, py + ph * 0.10), 22 * ui_scale,
		Color(N_MAGENTA.r, N_MAGENTA.g, N_MAGENTA.b, panel_alpha))
	var title_y = py + ph * 0.22
	var title_fs = clamp(int(fs(44)), 26, 48)
	for i in range(3):
		var off = i * 2 * ui_scale
		draw_string(active_font(), Vector2(px - off, title_y - off),
			tr_("revive_title"), HORIZONTAL_ALIGNMENT_CENTER, pw, title_fs,
			Color(1.0, 0.35, 0.95, (0.55 - i * 0.12) * panel_alpha))
	draw_string(active_font(), Vector2(px, title_y), tr_("revive_title"),
		HORIZONTAL_ALIGNMENT_CENTER, pw, title_fs, Color(1.0, 0.98, 1.0, panel_alpha))
	draw_string(active_font(), Vector2(px, py + ph * 0.32), tr_("revive_sub"),
		HORIZONTAL_ALIGNMENT_CENTER, pw, fs(18), Color(0.85, 0.9, 1.0, 0.9 * panel_alpha))
	draw_string(active_font(), Vector2(px, py + ph * 0.40),
		tr_("score") + "  " + str(score), HORIZONTAL_ALIGNMENT_CENTER, pw, fs(26),
		Color(1.0, 0.88, 0.30, panel_alpha))
	var giv_h = 34 * ui_scale
	var giv_w = pw * 0.68
	var giv_x = px + (pw - giv_w) / 2.0
	var giv_y = py + ph * 0.46
	var gs = StyleBoxFlat.new()
	gs.bg_color = Color(0.20, 0.15, 0.05, 0.9 * panel_alpha)
	gs.set_corner_radius_all(int(giv_h / 2.0))
	gs.border_width_top = int(1.5 * ui_scale); gs.border_width_bottom = int(1.5 * ui_scale)
	gs.border_width_left = int(1.5 * ui_scale); gs.border_width_right = int(1.5 * ui_scale)
	gs.border_color = Color(N_YELLOW.r, N_YELLOW.g, N_YELLOW.b, panel_alpha)
	draw_style_box(gs, Rect2(giv_x, giv_y, giv_w, giv_h))
	_draw_icon_gift(Vector2(giv_x + 22 * ui_scale, giv_y + giv_h / 2.0), 11 * ui_scale,
		Color(1.0, 0.95, 0.6, panel_alpha))
	draw_string(active_font(), Vector2(giv_x + 40 * ui_scale, giv_y + giv_h * 0.70),
		tr_("revive_gives"), HORIZONTAL_ALIGNMENT_CENTER, giv_w - 44 * ui_scale, fs(17),
		Color(N_YELLOW.r, N_YELLOW.g, N_YELLOW.b, panel_alpha))
	var btn_h = min(vp.y * 0.09, 76 * ui_scale) * panel_scale
	var btn_w = pw - 60 * ui_scale
	var btn_x = px + 30 * ui_scale
	var btn_y = py + ph - btn_h - 62 * ui_scale
	var btn_rect = Rect2(btn_x, btn_y, btn_w, btn_h)
	_draw_btn_3d(btn_rect, Color(N_GREEN.r, N_GREEN.g, N_GREEN.b, panel_alpha),
		Color(N_GREEN_SH.r, N_GREEN_SH.g, N_GREEN_SH.b, panel_alpha), not reduce_effects)
	var timer_r = btn_h * 0.35
	var timer_c = Vector2(btn_rect.position.x + 55 * ui_scale, btn_rect.position.y + btn_h / 2.0)
	var progress = 1.0 - (revive_timer / REVIVE_TIMER)
	var urgent = revive_timer <= REVIVE_URGENT_AT
	var arc_col = Color(1, 1, 1, 0.9)
	if urgent:
		var pulse = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.020)
		arc_col = Color(1.0, 0.35, 0.35, 0.9 + 0.1 * pulse)
		var warn_bg = StyleBoxFlat.new()
		warn_bg.bg_color = Color(1.0, 0.2, 0.2, 0.15 * pulse)
		warn_bg.set_corner_radius_all(int(btn_h * 0.42))
		draw_style_box(warn_bg, btn_rect)
	draw_arc(timer_c, timer_r, -PI / 2.0, -PI / 2.0 + TAU, 32, Color(0.2, 0.2, 0.3, 0.9), sw(3))
	draw_arc(timer_c, timer_r, -PI / 2.0, -PI / 2.0 + TAU * progress, 32, arc_col, sw(4))
	_draw_icon_video(timer_c, 8 * ui_scale, Color.WHITE)
	draw_string(active_font(),
		Vector2(btn_rect.position.x + 100 * ui_scale, btn_rect.position.y + btn_h * 0.68),
		tr_("revive_btn"), HORIZONTAL_ALIGNMENT_CENTER, btn_w - 130 * ui_scale, fs(24),
		Color(1.0, 1.0, 1.0, panel_alpha))
	var sep_y = btn_rect.position.y + btn_h + 14 * ui_scale
	var sep_w = pw * 0.5
	draw_line(Vector2(px + (pw - sep_w) / 2.0, sep_y),
		Vector2(px + (pw + sep_w) / 2.0, sep_y),
		Color(0.5, 0.4, 0.7, 0.35 * panel_alpha), sw(1))
	var no_h = 40 * ui_scale
	var no_w = pw * 0.55
	var no_x = px + (pw - no_w) / 2.0
	var no_y = sep_y + 10 * ui_scale
	var ns = StyleBoxFlat.new()
	ns.bg_color = Color(0.15, 0.10, 0.22, 0.6 * panel_alpha)
	ns.set_corner_radius_all(int(no_h / 2.0))
	draw_style_box(ns, Rect2(no_x, no_y, no_w, no_h))
	draw_string(active_font(), Vector2(no_x, no_y + no_h * 0.68),
		tr_("revive_no"), HORIZONTAL_ALIGNMENT_CENTER, no_w, fs(18),
		Color(0.85, 0.82, 0.95, 0.85 * panel_alpha))

# ============================================================================
# TUTORIAL / LOADING
# ============================================================================

func draw_tutorial_overlay():
	var vp = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.65))
	var pw = 720 * ui_scale; var ph = 430 * ui_scale
	var px = (vp.x - pw) / 2.0; var py = vp.y * 0.55
	_draw_panel(Rect2(px, py, pw, ph), Color(0.08, 0.03, 0.20, 0.98), 30, C_BORDER)
	var title = ""; var text = ""
	if tutorial_for_mode == GameMode.TIME:
		match tutorial_step:
			0: title = tr_("tut_time_t1"); text = tr_("tut_time_d1")
			1: title = tr_("tut_time_t2"); text = tr_("tut_time_d2")
			_: title = tr_("tut_ready_t"); text = tr_("tut_ready_d")
	else:
		match tutorial_step:
			0: title = tr_("tut_place_t"); text = tr_("tut_place_d")
			1: title = tr_("tut_lines_t"); text = tr_("tut_lines_d")
			2: title = tr_("tut_combo_t"); text = tr_("tut_combo_d")
			3: title = tr_("tut_ready_t"); text = tr_("tut_ready_d")
	var ic = Vector2(px + pw / 2.0, py + 80 * ui_scale)
	var icol = Color(1.0, 0.55, 1.0)
	match tutorial_step:
		0:
			draw_circle(ic + Vector2(0, -10 * ui_scale), 14 * ui_scale, icol)
			draw_colored_polygon(PackedVector2Array([
				ic + Vector2(0, 24 * ui_scale), ic + Vector2(16 * ui_scale, 6 * ui_scale),
				ic + Vector2(-16 * ui_scale, 6 * ui_scale)]), icol)
		_: _draw_icon_star(ic, 30 * ui_scale, icol)
	draw_string(active_font(), Vector2(px, py + fs(160)), title, HORIZONTAL_ALIGNMENT_CENTER, pw, fs(34), Color(1.0, 0.85, 1.0))
	draw_string(active_font(), Vector2(px + 40 * ui_scale, py + fs(230)), text, HORIZONTAL_ALIGNMENT_CENTER, pw - 80 * ui_scale, fs(22), Color(0.9, 0.9, 1.0))
	var total_steps = 3 if tutorial_for_mode == GameMode.TIME else 4
	for i in range(total_steps):
		var dx = px + pw / 2.0 + (i - (total_steps - 1) / 2.0) * 30 * ui_scale
		var col = Color(1.0, 0.4, 1.0) if i <= tutorial_step else Color(0.3, 0.25, 0.45)
		draw_circle(Vector2(dx, py + fs(290)), 6 * ui_scale, col)
	var br = Rect2(px + pw * 0.15, py + ph - 90 * ui_scale, pw * 0.7, 65 * ui_scale)
	var last_step = 2 if tutorial_for_mode == GameMode.TIME else 3
	var btxt = tr_("tut_done") if tutorial_step == last_step else tr_("tut_next")
	_draw_btn_3d(br, N_GREEN, N_GREEN_SH)
	draw_string(active_font(), br.position + Vector2(0, br.size.y * 0.62),
		btxt, HORIZONTAL_ALIGNMENT_CENTER, br.size.x, fs(28), Color.WHITE)

func advance_tutorial():
	tutorial_step += 1
	if tutorial_for_mode == GameMode.TIME:
		if tutorial_step >= 3:
			var f = FileAccess.open(TIME_TUTORIAL_SAVE, FileAccess.WRITE)
			if f != null: f.store_string("done"); f.close()
			tutorial_for_mode = 0; state = State.PLAYING
	else:
		if tutorial_step >= 4:
			var f = FileAccess.open(TUTORIAL_SAVE, FileAccess.WRITE)
			if f != null: f.store_string("done"); f.close()
			tutorial_for_mode = 0; state = State.MENU; _menu_enter_t = 0.0
	queue_redraw()

func draw_loading_screen():
	var vp = get_viewport_rect().size
	_draw_cosmic_bg(vp)
	_draw_menu_blocks()
	_draw_float_cubes(vp, 4, 0.35)
	var appear = clamp(loading_elapsed / 0.6, 0.0, 1.0)
	var base_y = vp.y * 0.42
	var fs_big = int(fs(88))
	for i in range(6, 0, -1):
		draw_string(active_font(), Vector2(0, base_y + i * ui_scale * 1.2),
			"BLOCK", HORIZONTAL_ALIGNMENT_CENTER, vp.x, fs_big,
			Color(0.10, 0.20, 0.55, (0.9 - i * 0.10) * appear))
	draw_string(active_font(), Vector2(0, base_y), "BLOCK",
		HORIZONTAL_ALIGNMENT_CENTER, vp.x, fs_big, Color(0.92, 0.98, 1.0, appear))
	for i in range(6, 0, -1):
		draw_string(active_font(), Vector2(0, base_y + fs(90) + i * ui_scale * 1.2),
			"SHIFT", HORIZONTAL_ALIGNMENT_CENTER, vp.x, fs_big,
			Color(0.55, 0.08, 0.02, (0.95 - i * 0.10) * appear))
	draw_string(active_font(), Vector2(0, base_y + fs(90)), "SHIFT",
		HORIZONTAL_ALIGNMENT_CENTER, vp.x, fs_big, Color(1.0, 0.55, 0.10, appear))
	draw_string(active_font(), Vector2(0, base_y + fs(170)),
		"THINK  ·  DRAG  ·  FILL", HORIZONTAL_ALIGNMENT_CENTER, vp.x,
		fs(20), Color(0.80, 0.88, 1.0, appear * 0.9))
	var bw = 560.0 * ui_scale; var bh = 16.0 * ui_scale
	var bx = (vp.x - bw) / 2.0; var by = vp.y * 0.78
	_draw_panel(Rect2(bx, by, bw, bh), Color(0.08, 0.03, 0.20), bh / 2.0, Color(0.4, 0.25, 0.75))
	var fw = bw * loading_progress
	if fw > 4:
		var f = StyleBoxFlat.new()
		f.bg_color = N_MAGENTA
		f.set_corner_radius_all(int((bh - 4) / 2.0))
		draw_style_box(f, Rect2(bx + 2, by + 2, fw - 4, bh - 4))
		draw_rect(Rect2(bx + 6, by + 4, max(0, fw - 12), (bh - 4) * 0.4), Color(1, 1, 1, 0.35))
		draw_circle(Vector2(bx + fw, by + bh / 2.0), bh * 0.9, Color(1.0, 0.7, 1.0, 0.5))
	draw_string(active_font(), Vector2(0, by - 22 * ui_scale), tr_("loading"),
		HORIZONTAL_ALIGNMENT_CENTER, vp.x, fs(20), Color(0.9, 0.85, 1.0))
	draw_string(active_font(), Vector2(0, by + bh + 26 * ui_scale),
		"%d%%" % int(loading_progress * 100.0), HORIZONTAL_ALIGNMENT_CENTER, vp.x, fs(20),
		Color(0.8, 0.7, 1.0, 0.85))
	if loading_elapsed > 0.8:
		var tk = ["tip1", "tip2", "tip3", "tip4"]
		var ti = int(loading_elapsed * 0.5) % tk.size()
		var ta = clamp((loading_elapsed - 0.8) * 2.0, 0.0, 1.0)
		var fade = 0.6 + 0.4 * sin(loading_elapsed * 1.2)
		draw_string(active_font(), Vector2(0, by + 90 * ui_scale), tr_(tk[ti]),
			HORIZONTAL_ALIGNMENT_CENTER, vp.x, fs(20), Color(0.85, 0.75, 1.0, ta * fade * 0.9))

# ============================================================================
# MENU
# ============================================================================

func draw_menu():
	var vp = get_viewport_rect().size
	var t = Time.get_ticks_msec() * 0.001
	var ease_in = ease(_menu_enter_t, 0.4)
	_draw_cosmic_bg(vp)
	_draw_menu_blocks()
	_draw_float_cubes(vp, 5, 0.65)
	_draw_center_burst(vp)
	var logo_c = Vector2(vp.x / 2.0, vp.y * 0.24)
	var breathe = 0.94 + 0.06 * sin(t * 1.1)
	for i in range(8):
		draw_circle(logo_c, (110 + i * 60) * ui_scale * breathe,
			Color(0.75, 0.30, 1.0, (0.06 - i * 0.006) * ease_in))
	var fs_big = int(fs(104))
	var log_y = logo_c.y
	for i in range(7, 0, -1):
		draw_string(active_font(), Vector2(0, log_y + i * ui_scale * 1.4),
			"BLOCK", HORIZONTAL_ALIGNMENT_CENTER, vp.x, fs_big,
			Color(0.08, 0.18, 0.55, 0.92 * ease_in))
	for i in range(3, 0, -1):
		draw_string(active_font(), Vector2(0, log_y - i * ui_scale),
			"BLOCK", HORIZONTAL_ALIGNMENT_CENTER, vp.x, fs_big,
			Color(0.55, 0.85, 1.0, 0.4 * ease_in))
	draw_string(active_font(), Vector2(0, log_y), "BLOCK",
		HORIZONTAL_ALIGNMENT_CENTER, vp.x, fs_big, Color(0.98, 0.99, 1.0, ease_in))
	var log_y2 = log_y + fs(104)
	for i in range(7, 0, -1):
		draw_string(active_font(), Vector2(0, log_y2 + i * ui_scale * 1.4),
			"SHIFT", HORIZONTAL_ALIGNMENT_CENTER, vp.x, fs_big,
			Color(0.55, 0.06, 0.02, 0.95 * ease_in))
	for i in range(3, 0, -1):
		draw_string(active_font(), Vector2(0, log_y2 - i * ui_scale),
			"SHIFT", HORIZONTAL_ALIGNMENT_CENTER, vp.x, fs_big,
			Color(1.0, 0.85, 0.25, 0.42 * ease_in))
	var orange = Color(1.0, 0.55, 0.10).lerp(Color(1.0, 0.75, 0.30), 0.5 + 0.5 * sin(t * 2.0))
	draw_string(active_font(), Vector2(0, log_y2), "SHIFT",
		HORIZONTAL_ALIGNMENT_CENTER, vp.x, fs_big, Color(orange.r, orange.g, orange.b, ease_in))
	var r = _menu_button_rects()
	if daily_bonus_available:
		var d = r["daily"]
		var pulse = 0.7 + 0.3 * sin(t * 4.0)
		_draw_glow(d, N_YELLOW, 3, 5.0, 0.28 * pulse)
		_draw_panel(d, Color(0.30, 0.20, 0.02, 0.96), 22, N_YELLOW)
		_draw_icon_gift(d.position + Vector2(32 * ui_scale, d.size.y / 2.0), 14 * ui_scale,
			Color(1.0, 0.95, 0.6))
		draw_string(active_font(), d.position + Vector2(58 * ui_scale, d.size.y * 0.40),
			tr_("daily_bonus"), HORIZONTAL_ALIGNMENT_LEFT, -1, fs(14), Color(1.0, 0.95, 0.6))
		draw_string(active_font(), d.position + Vector2(58 * ui_scale, d.size.y * 0.76),
			"x%d   +%d" % [stats.daily_streak, DAILY_BONUS_SCORE * max(1, stats.daily_streak)],
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs(19), Color.WHITE)
	_draw_stats_card(r["stats"], ease_in)
	var pr = r["play"]
	var play_breathe = 1.0 + 0.015 * sin(t * 2.2)
	var play_draw = Rect2(pr.position - pr.size * (play_breathe - 1.0) * 0.5, pr.size * play_breathe)
	_draw_glow(play_draw, N_GREEN, 5, 6.0, 0.24)
	_draw_btn_3d(play_draw, N_GREEN, N_GREEN_SH)
	_draw_icon_play(Vector2(play_draw.position.x + 80 * ui_scale,
		play_draw.position.y + play_draw.size.y * 0.46), 28 * ui_scale, Color.WHITE)
	draw_string(active_font(),
		Vector2(play_draw.position.x + 50 * ui_scale, play_draw.position.y + play_draw.size.y * 0.68),
		tr_("start_game").to_upper(), HORIZONTAL_ALIGNMENT_CENTER,
		play_draw.size.x - 100 * ui_scale, fs(38), Color.WHITE)
	_draw_menu_tile(r["settings"], N_BLUE, "gear", tr_("settings"))
	_draw_menu_tile(r["skins"], N_PURPLE, "star", tr_("skins"))
	_draw_menu_tile(r["achievements"], N_ORANGE, "trophy", tr_("achievements"))
	if has_saved_game:
		_draw_menu_tile(r["continue"], N_CYAN, "play", tr_("continue"))
	else:
		_draw_menu_tile(r["continue"], Color(0.20, 0.16, 0.30), "play", tr_("continue"), true)
	_draw_small_toggle(vp, 0, sound_enabled, "sound")
	_draw_small_toggle(vp, 1, music_enabled, "music")
	_draw_small_toggle(vp, 2, true, "settings")
	draw_string(active_font(),
		Vector2(vp.x - 100 * ui_scale, vp.y - _safe_insets.w - 24 * ui_scale),
		"v" + GAME_VERSION, HORIZONTAL_ALIGNMENT_RIGHT, 80 * ui_scale, fs(14), Color(1, 1, 1, 0.4))

func _draw_menu_tile(rect: Rect2, col: Color, icon: String, label: String, locked: bool = false):
	var use_col = col
	if locked: use_col = Color(0.25, 0.22, 0.32)
	var sh = Color(use_col.r * 0.35, use_col.g * 0.35, use_col.b * 0.35)
	_draw_btn_3d(rect, use_col, sh, false)
	var ic = Vector2(rect.position.x + 42 * ui_scale, rect.position.y + rect.size.y * 0.44)
	var icol = Color.WHITE if not locked else Color(0.5, 0.5, 0.6)
	var isz = 18 * ui_scale
	match icon:
		"gear": _draw_icon_gear(ic, isz, icol)
		"star": _draw_icon_star(ic, isz, icol)
		"trophy": _draw_icon_trophy(ic, isz, icol)
		"play": _draw_icon_play(ic, isz * 0.9, icol)
	draw_string(active_font(), Vector2(rect.position.x + 76 * ui_scale, rect.position.y + rect.size.y * 0.62),
		label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 90 * ui_scale, fs(22), icol)

func _draw_stats_card(c: Rect2, alpha: float):
	_draw_panel(c, Color(0.08, 0.03, 0.22, 0.75 * alpha), 22,
		Color(0.55, 0.35, 1.0, 0.55 * alpha))
	var items = [
		{"icon": "trophy", "val": str(high_score), "col": N_YELLOW},
		{"icon": "lines", "val": str(stats.total_lines), "col": N_CYAN},
		{"icon": "flame", "val": "x" + str(stats.daily_streak), "col": N_ORANGE},
	]
	var seg = c.size.x / float(items.size())
	for i in range(items.size()):
		var ix = c.position.x + seg * (i + 0.5)
		var iy = c.position.y + c.size.y * 0.50
		var col = items[i].col
		var icon_off = 44 * ui_scale
		match items[i].icon:
			"trophy": _draw_icon_trophy(Vector2(ix - icon_off, iy), 12 * ui_scale, col)
			"lines":
				draw_rect(Rect2(ix - icon_off - 8 * ui_scale, iy - 8 * ui_scale,
					16 * ui_scale, 16 * ui_scale), col)
			"flame": _draw_icon_flame(Vector2(ix - icon_off, iy), 12 * ui_scale, col)
		draw_string(active_font(), Vector2(ix - 22 * ui_scale, iy + 8 * ui_scale),
			items[i].val, HORIZONTAL_ALIGNMENT_LEFT, -1, fs(22), col)
		if i < items.size() - 1:
			var sx = c.position.x + seg * (i + 1)
			draw_line(Vector2(sx, c.position.y + 14 * ui_scale),
				Vector2(sx, c.position.y + c.size.y - 14 * ui_scale),
				Color(0.55, 0.35, 1.0, 0.25 * alpha), sw(1))

func _draw_small_toggle(vp: Vector2, idx: int, active: bool, kind: String):
	var sz = 60 * ui_scale
	var gap = 16 * ui_scale
	var x0 = _safe_insets.x + 30 * ui_scale
	var y0 = vp.y - _safe_insets.w - sz - 30 * ui_scale
	var r = Rect2(x0 + idx * (sz + gap), y0, sz, sz)
	var col = N_BLUE if active else Color(0.15, 0.08, 0.25)
	_draw_panel(r, col, 16, Color(0.55, 0.75, 1.0, 0.85))
	var c = r.position + r.size / 2.0
	var icol = Color.WHITE if active else Color(0.7, 0.7, 0.85)
	var isz = 18 * ui_scale
	match kind:
		"sound": _draw_icon_speaker(c, isz, icol, active)
		"music": _draw_icon_music(c, isz, icol)
		"settings": _draw_icon_gear(c, isz * 0.9, icol)

# ============================================================================
# MODE SELECT
# ============================================================================

func draw_mode_select():
	var vp = get_viewport_rect().size
	_draw_cosmic_bg(vp)
	draw_string(active_font(), to_screen(Vector2(0, 320)), tr_("mode_select"),
		HORIZONTAL_ALIGNMENT_CENTER, to_screen_size(Vector2(REF_SIZE.x, 0)).x, fs(46),
		Color(1.0, 0.95, 1.0))
	var modes = [
		{"name": tr_("mode_classic"), "desc": tr_("mode_classic_desc"),
		 "color": N_CYAN, "rec": high_score, "rec_lbl": tr_("best")},
		{"name": tr_("mode_time"), "desc": tr_("mode_time_desc"),
		 "color": N_MAGENTA, "rec": time_high, "rec_lbl": tr_("best")},
		{"name": tr_("mode_campaign"), "desc": tr_("mode_campaign_desc"),
		 "color": N_PURPLE, "rec": campaign_max_unlocked - 1, "rec_lbl": tr_("level")},
	]
	for idx in range(3):
		var m = modes[idx]
		var y = 440 + idx * 220
		var rect = to_screen_rect(Rect2(100, y, 700, 180))
		_draw_panel(rect, Color(m.color.r * 0.12, m.color.g * 0.06, m.color.b * 0.25, 0.95),
			24, m.color)
		draw_string(active_font(), rect.position + Vector2(40 * ui_scale, rect.size.y * 0.42),
			m.name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs(38), m.color)
		draw_string(active_font(), rect.position + Vector2(40 * ui_scale, rect.size.y * 0.72),
			m.desc, HORIZONTAL_ALIGNMENT_LEFT, -1, fs(20), Color(0.85, 0.85, 1.0, 0.75))
		_draw_icon_star(rect.position + Vector2(rect.size.x - 240 * ui_scale, rect.size.y * 0.5),
			16 * ui_scale, N_YELLOW)
		draw_string(active_font(),
			rect.position + Vector2(rect.size.x - 210 * ui_scale, rect.size.y * 0.58),
			str(m.rec), HORIZONTAL_ALIGNMENT_LEFT, -1, fs(24), Color(1, 0.9, 0.3))
	draw_button(BACK_BUTTON, tr_("back"), true)

func handle_mode_select_click(pos):
	if not _try_ui_action(): return
	if to_screen_rect(BACK_BUTTON).has_point(pos):
		play_sfx(sfx_button); state = State.MENU; _menu_enter_t = 0.0; return
	if to_screen_rect(Rect2(100, 440, 700, 180)).has_point(pos):
		play_sfx(sfx_button); start_classic_game(); return
	if to_screen_rect(Rect2(100, 660, 700, 180)).has_point(pos):
		play_sfx(sfx_button); start_time_game(); return
	if to_screen_rect(Rect2(100, 880, 700, 180)).has_point(pos):
		play_sfx(sfx_button)
		campaign_page = max(0, (campaign_max_unlocked - 1) / CAMP_PAGE_SIZE)
		state = State.CAMPAIGN_MAP
		return

# ============================================================================
# SKINS (v1.5.1 — improved screen)
# ============================================================================

const SKIN_CARD_H = 130.0
const SKIN_CARD_GAP = 16.0
const SKIN_START_Y = 260.0

func _skin_card_rect(idx: int) -> Rect2:
	return Rect2(60, SKIN_START_Y + idx * (SKIN_CARD_H + SKIN_CARD_GAP), 780, SKIN_CARD_H)

func _skin_select_button_rect(idx: int) -> Rect2:
	return Rect2(610, SKIN_START_Y + idx * (SKIN_CARD_H + SKIN_CARD_GAP) + 40, 190, 50)

func draw_skins_screen():
	var vp = get_viewport_rect().size
	_draw_cosmic_bg(vp)
	draw_string(active_font(), to_screen(Vector2(0, 180)), tr_("skins_title"),
		HORIZONTAL_ALIGNMENT_CENTER, to_screen_size(Vector2(REF_SIZE.x, 0)).x, fs(42),
		Color(1.0, 0.95, 1.0))
	draw_string(active_font(), to_screen(Vector2(0, 222)),
		_skin_name(_current_skin()) + " · " + tr_("active"),
		HORIZONTAL_ALIGNMENT_CENTER, to_screen_size(Vector2(REF_SIZE.x, 0)).x, fs(16),
		Color(0.85, 0.85, 1.0, 0.7))
	for i in range(SKINS.size()): _draw_skin_card(i, SKINS[i])
	var back_y = SKIN_START_Y + SKINS.size() * (SKIN_CARD_H + SKIN_CARD_GAP) + 30
	var back_rect = to_screen_rect(Rect2(280, back_y, 340, 65))
	_draw_btn_3d(back_rect, N_BLUE, N_BLUE_SH)
	draw_string(active_font(),
		back_rect.position + Vector2(0, back_rect.size.y * 0.62),
		tr_("back"), HORIZONTAL_ALIGNMENT_CENTER, back_rect.size.x, fs(24), Color.WHITE)
	_skin_back_rect = back_rect

func _draw_skin_card(idx: int, skin: Dictionary):
	var rect = to_screen_rect(_skin_card_rect(idx))
	var active = skin.id == current_skin_id
	if active:
		_draw_glow(rect, N_MAGENTA, 3, 5.0, 0.22)
	_draw_panel(rect, Color(0.06, 0.03, 0.16, 0.95), 20,
		N_MAGENTA if active else Color(0.35, 0.22, 0.62, 0.65))
	var preview_size = 96 * ui_scale
	var preview_x = rect.position.x + 22 * ui_scale
	var preview_y = rect.position.y + (rect.size.y - preview_size) / 2.0
	var bs = preview_size / 2.0 - 4 * ui_scale
	var gap = 6 * ui_scale
	var pv_colors = [Color("#2EC4FF"), Color("#9BFF3D"), Color("#FF2FD0"), Color("#FF9E2C")]
	_render_block_styled(Rect2(Vector2(preview_x, preview_y), Vector2(bs, bs)), pv_colors[0], skin)
	_render_block_styled(Rect2(Vector2(preview_x + bs + gap, preview_y), Vector2(bs, bs)), pv_colors[1], skin)
	_render_block_styled(Rect2(Vector2(preview_x, preview_y + bs + gap), Vector2(bs, bs)), pv_colors[2], skin)
	_render_block_styled(Rect2(Vector2(preview_x + bs + gap, preview_y + bs + gap), Vector2(bs, bs)), pv_colors[3], skin)
	var name_x = preview_x + preview_size + 22 * ui_scale
	var name_y = rect.position.y + rect.size.y * 0.42
	draw_string(active_font(), Vector2(name_x, name_y),
		_skin_name(skin), HORIZONTAL_ALIGNMENT_LEFT, -1, fs(28), Color.WHITE)
	var style_tag = skin.get("style", "neon")
	var style_col = N_CYAN
	match style_tag:
		"outline": style_col = N_ORANGE
		"soft": style_col = Color(1.0, 0.85, 0.9)
		"glow": style_col = N_MAGENTA
		"neon": style_col = N_GREEN
	draw_string(active_font(), Vector2(name_x, name_y + 24 * ui_scale),
		"· " + style_tag.to_upper() + " ·", HORIZONTAL_ALIGNMENT_LEFT, -1, fs(14), style_col)
	if active:
		var chk = Vector2(rect.position.x + rect.size.x - 110 * ui_scale,
			rect.position.y + rect.size.y * 0.5)
		_draw_icon_check(chk, 14 * ui_scale, Color(0.55, 1.0, 0.7))
		draw_string(active_font(),
			Vector2(rect.position.x + rect.size.x - 88 * ui_scale,
				rect.position.y + rect.size.y * 0.55),
			tr_("active"), HORIZONTAL_ALIGNMENT_LEFT, -1, fs(20),
			Color(0.55, 1.0, 0.7))
	else:
		var br = to_screen_rect(_skin_select_button_rect(idx))
		_draw_btn_3d(br, Color(0.20, 0.45, 0.20), Color(0.10, 0.25, 0.10))
		var frame = StyleBoxFlat.new()
		frame.bg_color = Color(0, 0, 0, 0)
		frame.set_corner_radius_all(int(br.size.y * 0.42))
		frame.border_width_top = int(2 * ui_scale)
		frame.border_width_bottom = int(2 * ui_scale)
		frame.border_width_left = int(2 * ui_scale)
		frame.border_width_right = int(2 * ui_scale)
		frame.border_color = Color(0.6, 1.0, 0.6, 0.9)
		draw_style_box(frame, br)
		draw_string(active_font(),
			br.position + Vector2(0, br.size.y * 0.62),
			tr_("select"), HORIZONTAL_ALIGNMENT_CENTER, br.size.x, fs(22),
			Color(0.85, 1.0, 0.85))

func handle_skins_click(pos):
	if not _try_ui_action(): return
	if _skin_back_rect.has_point(pos):
		play_sfx(sfx_button); state = State.MENU; _menu_enter_t = 0.0; return
	for i in range(SKINS.size()):
		var skin = SKINS[i]
		if skin.id == current_skin_id: continue
		if to_screen_rect(_skin_select_button_rect(i)).has_point(pos):
			current_skin_id = skin.id
			stats.skins_used[skin.id] = true
			save_skin()
			play_sfx(sfx_button); check_achievements(); save_progress()
			return

# ============================================================================
# ACHIEVEMENTS
# ============================================================================

func draw_achievements_screen():
	var vp = get_viewport_rect().size
	_draw_cosmic_bg(vp)
	draw_string(active_font(), to_screen(Vector2(0, 200)), tr_("achievements_title"),
		HORIZONTAL_ALIGNMENT_CENTER, to_screen_size(Vector2(REF_SIZE.x, 0)).x, fs(46),
		Color(1.0, 0.95, 1.0))
	var unlocked_count = 0
	for a in ACHIEVEMENTS:
		if _is_unlocked(a.id): unlocked_count += 1
	draw_string(active_font(), to_screen(Vector2(0, 262)),
		"%d / %d" % [unlocked_count, ACHIEVEMENTS.size()],
		HORIZONTAL_ALIGNMENT_CENTER, to_screen_size(Vector2(REF_SIZE.x, 0)).x, fs(24),
		Color(1, 0.85, 0.25))
	var pbw = 520.0 * ui_scale
	var pbx = (vp.x - pbw) / 2.0
	var pby = to_screen(Vector2(0, 298)).y
	_draw_panel(Rect2(pbx, pby, pbw, 9 * ui_scale), Color(0.10, 0.05, 0.22), 6, Color(0.4, 0.25, 0.75))
	var fr = float(unlocked_count) / float(ACHIEVEMENTS.size())
	if fr > 0:
		var pf = StyleBoxFlat.new()
		pf.bg_color = N_MAGENTA
		pf.set_corner_radius_all(int(6 * ui_scale))
		draw_style_box(pf, Rect2(pbx, pby, pbw * fr, 9 * ui_scale))
	var top_y = to_screen(Vector2(0, ACH_TOP_Y)).y
	var bottom_y = to_screen(Vector2(0, ACH_BOTTOM_Y)).y
	var scroll = ach_scroll_px * ui_scale
	var ch = ACH_CARD_H * ui_scale
	var cg = ACH_CARD_GAP * ui_scale
	for i in range(ACHIEVEMENTS.size()):
		var a = ACHIEVEMENTS[i]
		var cy = top_y + i * (ch + cg) - scroll
		if cy + ch < top_y - 10: continue
		if cy > bottom_y + 10: continue
		var r = Rect2(to_screen(Vector2(50, 0)).x, cy, to_screen_size(Vector2(800, 0)).x, ch)
		if r.position.y < top_y:
			var clip = top_y - r.position.y
			r.position.y = top_y; r.size.y -= clip
		if r.position.y + r.size.y > bottom_y: r.size.y = bottom_y - r.position.y
		if r.size.y <= 4: continue
		_draw_ach_card(a, r, _is_unlocked(a.id))
	if ach_scroll_px > 5:
		_draw_icon_chevron(to_screen(Vector2(REF_SIZE.x / 2.0, 322)), 10 * ui_scale, Color(1, 1, 1, 0.5))
	if ach_scroll_px < _ach_max_scroll() - 5:
		_draw_icon_chevron(to_screen(Vector2(REF_SIZE.x / 2.0, 1450)), 10 * ui_scale, Color(1, 1, 1, 0.5))
	draw_button(BACK_BUTTON, tr_("back"), true)

func _draw_ach_card(a, rect: Rect2, unlocked: bool):
	var border = Color(0.4, 1.0, 0.65) if unlocked else Color(0.55, 0.35, 1.0, 0.65)
	var bg = Color(0.06, 0.15, 0.14, 0.95) if unlocked else Color(0.06, 0.03, 0.16, 0.95)
	_draw_panel(rect, bg, 18, border)
	var ix = rect.position.x + rect.size.x - 60 * ui_scale
	var iy = rect.position.y + rect.size.y / 2.0
	if unlocked:
		for i in range(3):
			draw_circle(Vector2(ix, iy), (24 + i * 5) * ui_scale, Color(1.0, 0.85, 0.25, 0.20 - i * 0.05))
		_draw_icon_star(Vector2(ix, iy), 22 * ui_scale, N_YELLOW)
	else:
		var prog = _ach_progress(a.id)
		var ratio = clamp(float(prog) / float(a.g), 0.0, 1.0)
		var bw = 140 * ui_scale
		var bx = ix - bw / 2.0
		var by = iy + 12 * ui_scale
		_draw_panel(Rect2(bx, by, bw, 8 * ui_scale), Color(0.14, 0.08, 0.24, 0.9), 4, Color(0.4, 0.25, 0.75))
		if ratio > 0:
			var pf = StyleBoxFlat.new()
			pf.bg_color = N_MAGENTA
			pf.set_corner_radius_all(int(4 * ui_scale))
			draw_style_box(pf, Rect2(bx, by, bw * ratio, 8 * ui_scale))
		draw_string(active_font(), Vector2(bx, iy + 2 * ui_scale),
			"%d/%d" % [prog, a.g], HORIZONTAL_ALIGNMENT_CENTER, bw, fs(20), Color(1, 1, 1, 0.75))
	draw_string(active_font(), rect.position + Vector2(25 * ui_scale, rect.size.y * 0.42),
		_ach_name(a.id), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 200 * ui_scale, fs(26),
		Color.WHITE if unlocked else Color(0.85, 0.85, 0.95, 0.85))
	draw_string(active_font(), rect.position + Vector2(25 * ui_scale, rect.size.y * 0.78),
		_ach_desc(a.id), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 200 * ui_scale, fs(18),
		Color(1, 1, 1, 0.55))

func handle_achievements_click(pos):
	if not _try_ui_action(): return
	if to_screen_rect(BACK_BUTTON).has_point(pos):
		play_sfx(sfx_button); state = State.MENU; _menu_enter_t = 0.0; return
	ach_dragging = true
	ach_drag_start_y = pos.y
	ach_drag_start_scroll = ach_scroll_px
	ach_last_move_y = pos.y
	ach_last_move_time = Time.get_ticks_msec() / 1000.0
	ach_velocity = 0.0

# ============================================================================
# CAMPAIGN
# ============================================================================

func _camp_cell_rect(idx_in_page: int) -> Rect2:
	var row = idx_in_page / CAMP_COLS
	var col = idx_in_page % CAMP_COLS
	var total_w = CAMP_COLS * CAMP_CELL_W + (CAMP_COLS - 1) * CAMP_CELL_GAP
	var start_x = (REF_SIZE.x - total_w) / 2.0
	return Rect2(
		start_x + col * (CAMP_CELL_W + CAMP_CELL_GAP),
		CAMP_START_Y + row * (CAMP_CELL_H + CAMP_CELL_GAP),
		CAMP_CELL_W, CAMP_CELL_H)

func _camp_nav_rect(side: int) -> Rect2:
	var nav_y = CAMP_START_Y + CAMP_ROWS * (CAMP_CELL_H + CAMP_CELL_GAP) + 30
	if side == 0: return Rect2(100, nav_y, 200, 60)
	return Rect2(600, nav_y, 200, 60)

func draw_campaign_screen():
	var vp = get_viewport_rect().size
	_draw_cosmic_bg(vp)
	var total_pages = int(ceil(float(CAMP_TOTAL_LEVELS) / CAMP_PAGE_SIZE))
	draw_string(active_font(), to_screen(Vector2(0, 200)), tr_("campaign_title"),
		HORIZONTAL_ALIGNMENT_CENTER, to_screen_size(Vector2(REF_SIZE.x, 0)).x, fs(46),
		Color(1.0, 0.95, 1.0))
	draw_string(active_font(), to_screen(Vector2(0, 262)),
		"%d / %d   ·   %s %d / %d" % [
			campaign_max_unlocked - 1, CAMP_TOTAL_LEVELS,
			tr_("level"), campaign_page + 1, total_pages],
		HORIZONTAL_ALIGNMENT_CENTER, to_screen_size(Vector2(REF_SIZE.x, 0)).x, fs(20),
		Color(0.85, 0.85, 1.0, 0.85))
	var pbw = 520.0 * ui_scale
	var pbx = (vp.x - pbw) / 2.0
	var pby = to_screen(Vector2(0, 300)).y
	_draw_panel(Rect2(pbx, pby, pbw, 9 * ui_scale), Color(0.10, 0.05, 0.22), 6, Color(0.4, 0.25, 0.75))
	var fr = float(campaign_max_unlocked - 1) / float(CAMP_TOTAL_LEVELS)
	if fr > 0:
		var pf = StyleBoxFlat.new()
		pf.bg_color = N_YELLOW
		pf.set_corner_radius_all(int(6 * ui_scale))
		draw_style_box(pf, Rect2(pbx, pby, pbw * fr, 9 * ui_scale))
	for i in range(CAMP_PAGE_SIZE):
		var lvl = campaign_page * CAMP_PAGE_SIZE + i + 1
		if lvl > CAMP_TOTAL_LEVELS: break
		var rect = to_screen_rect(_camp_cell_rect(i))
		_draw_camp_level(lvl, rect)
	var prev_r = to_screen_rect(_camp_nav_rect(0))
	var next_r = to_screen_rect(_camp_nav_rect(1))
	var can_prev = campaign_page > 0
	var can_next = campaign_page < total_pages - 1
	if can_prev:
		_draw_btn_3d(prev_r, N_BLUE, N_BLUE_SH)
		draw_string(active_font(), prev_r.position + Vector2(0, prev_r.size.y * 0.62),
			"◄", HORIZONTAL_ALIGNMENT_CENTER, prev_r.size.x, fs(30), Color.WHITE)
	else:
		_draw_panel(prev_r, Color(0.10, 0.08, 0.15, 0.7), 20, Color(0.3, 0.25, 0.4, 0.5))
	if can_next:
		_draw_btn_3d(next_r, N_BLUE, N_BLUE_SH)
		draw_string(active_font(), next_r.position + Vector2(0, next_r.size.y * 0.62),
			"►", HORIZONTAL_ALIGNMENT_CENTER, next_r.size.x, fs(30), Color.WHITE)
	else:
		_draw_panel(next_r, Color(0.10, 0.08, 0.15, 0.7), 20, Color(0.3, 0.25, 0.4, 0.5))
	draw_button(BACK_BUTTON, tr_("back"), true)

func _draw_camp_level(lvl: int, rect: Rect2):
	var unlocked = lvl <= campaign_max_unlocked
	var stars = int(level_stars_saved.get(lvl, 0))
	var border_col = C_BORDER
	var bg = Color(0.08, 0.03, 0.20, 0.92)
	var text_col = Color.WHITE
	if not unlocked:
		border_col = Color(0.25, 0.18, 0.35, 0.6)
		bg = Color(0.05, 0.03, 0.12, 0.85)
		text_col = Color(0.5, 0.45, 0.6)
	elif stars > 0:
		border_col = N_YELLOW
		_draw_glow(rect, N_YELLOW, 2, 3.0, 0.15)
	_draw_panel(rect, bg, 18, border_col)
	if unlocked:
		draw_string(active_font(),
			Vector2(rect.position.x + 24 * ui_scale, rect.position.y + rect.size.y * 0.65),
			str(lvl), HORIZONTAL_ALIGNMENT_LEFT, -1, fs(30), text_col)
		var star_y = rect.position.y + rect.size.y * 0.5
		var star_start = rect.position.x + rect.size.x - 84 * ui_scale
		for i in range(3):
			var sx = star_start + i * 24 * ui_scale
			var col = N_YELLOW if i < stars else Color(0.3, 0.25, 0.4)
			_draw_icon_star(Vector2(sx, star_y), 10 * ui_scale, col)
	else:
		draw_string(active_font(),
			Vector2(rect.position.x, rect.position.y + rect.size.y * 0.62),
			str(lvl), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 40 * ui_scale,
			fs(26), text_col)
		_draw_icon_lock(Vector2(rect.position.x + rect.size.x - 30 * ui_scale,
			rect.position.y + rect.size.y * 0.5), 12 * ui_scale, text_col)

func handle_campaign_click(pos):
	if not _try_ui_action(): return
	if to_screen_rect(BACK_BUTTON).has_point(pos):
		play_sfx(sfx_button); state = State.MODE_SELECT; return
	var total_pages = int(ceil(float(CAMP_TOTAL_LEVELS) / CAMP_PAGE_SIZE))
	if to_screen_rect(_camp_nav_rect(0)).has_point(pos):
		if campaign_page > 0:
			campaign_page -= 1; play_sfx(sfx_button)
		return
	if to_screen_rect(_camp_nav_rect(1)).has_point(pos):
		if campaign_page < total_pages - 1:
			campaign_page += 1; play_sfx(sfx_button)
		return
	for i in range(CAMP_PAGE_SIZE):
		var lvl = campaign_page * CAMP_PAGE_SIZE + i + 1
		if lvl > CAMP_TOTAL_LEVELS: break
		if to_screen_rect(_camp_cell_rect(i)).has_point(pos):
			if lvl <= campaign_max_unlocked:
				play_sfx(sfx_button)
				start_campaign_level(lvl)
			else:
				play_sfx(sfx_button, 0.7)
			return

# ============================================================================
# SETTINGS
# ============================================================================

func weather_text_local() -> String:
	match weather_mode:
		0: return tr_("weather_off")
		1: return tr_("weather_snow")
		2: return tr_("weather_rain")
	return ""

func _settings_row_rects() -> Dictionary:
	var vp = get_viewport_rect().size
	var rw = 800 * ui_scale; var rh = 84 * ui_scale
	var rx = (vp.x - rw) / 2.0
	var sy = to_screen(Vector2(0, 360)).y
	var gap = 16 * ui_scale
	return {
		"music": Rect2(rx, sy + 0 * (rh + gap), rw, rh),
		"sound": Rect2(rx, sy + 1 * (rh + gap), rw, rh),
		"vibro": Rect2(rx, sy + 2 * (rh + gap), rw, rh),
		"weather": Rect2(rx, sy + 3 * (rh + gap), rw, rh),
		"effects": Rect2(rx, sy + 4 * (rh + gap), rw, rh),
		"lang": Rect2(rx, sy + 5 * (rh + gap), rw, rh),
		"reset": Rect2(rx, sy + 6 * (rh + gap), rw, rh),
	}

func draw_settings_screen():
	var vp = get_viewport_rect().size
	_draw_cosmic_bg(vp)
	var r = _settings_row_rects()
	var hdr_y = to_screen(Vector2(0, 180)).y
	draw_string(active_font(), Vector2(0, hdr_y + fs(36)),
		tr_("settings_title"), HORIZONTAL_ALIGNMENT_CENTER, vp.x, fs(44), Color(1.0, 0.95, 1.0))
	var back_rect = Rect2(_safe_insets.x + 28 * ui_scale, hdr_y - 10 * ui_scale, 80 * ui_scale, 80 * ui_scale)
	_draw_panel(back_rect, C_PANEL, 20, C_BORDER)
	_draw_icon_chevron(back_rect.position + back_rect.size / 2.0, 16 * ui_scale, Color.WHITE, true)
	_draw_settings_row(r["music"], "music", tr_("music"), music_enabled, N_GREEN if music_enabled else Color(0.5, 0.4, 0.65))
	_draw_settings_row(r["sound"], "sound", tr_("sound"), sound_enabled, N_GREEN if sound_enabled else Color(0.5, 0.4, 0.65))
	_draw_settings_row(r["vibro"], "vibration", tr_("vibration"), vibration_enabled, N_GREEN if vibration_enabled else Color(0.5, 0.4, 0.65))
	_draw_settings_row_text(r["weather"], "weather", tr_("weather"), weather_text_local(), N_CYAN)
	_draw_settings_row(r["effects"], "effects", tr_("reduce_effects"), not reduce_effects, N_GREEN if not reduce_effects else Color(0.5, 0.4, 0.65))
	_draw_settings_row_text(r["lang"], "lang", tr_("language"), current_lang.to_upper(), N_CYAN)
	var rst = r["reset"]
	_draw_btn_3d(rst, N_ORANGE, N_ORANGE_SH)
	draw_string(active_font(), rst.position + Vector2(0, rst.size.y * 0.66),
		tr_("reset_score"), HORIZONTAL_ALIGNMENT_CENTER, rst.size.x, fs(26), Color.WHITE)

func _draw_settings_row(rect: Rect2, icon: String, label: String, is_on: bool, accent: Color):
	_draw_panel(rect, Color(0.06, 0.03, 0.16, 0.9), 18, Color(0.35, 0.25, 0.65, 0.7))
	var ic = rect.position + Vector2(50 * ui_scale, rect.size.y / 2.0)
	var isz = 20 * ui_scale
	var icol = Color(0.85, 0.90, 1.0)
	match icon:
		"music": _draw_icon_music(ic, isz, icol)
		"sound": _draw_icon_speaker(ic, isz, icol, true)
		"vibration": _draw_icon_vibration(ic, isz, icol)
		"effects": _draw_icon_star(ic, isz, icol)
	draw_string(active_font(), Vector2(rect.position.x + 90 * ui_scale, rect.position.y + rect.size.y * 0.58),
		label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs(24), Color.WHITE)
	var sw_w = 74 * ui_scale; var sw_h = 40 * ui_scale
	var sw_x = rect.position.x + rect.size.x - sw_w - 30 * ui_scale
	var sw_y = rect.position.y + (rect.size.y - sw_h) / 2.0
	var sw_rect = Rect2(sw_x, sw_y, sw_w, sw_h)
	var track = StyleBoxFlat.new()
	track.bg_color = accent if is_on else Color(0.20, 0.15, 0.30)
	track.set_corner_radius_all(int(sw_h / 2.0))
	track.border_width_top = int(1.5 * ui_scale); track.border_width_bottom = int(1.5 * ui_scale)
	track.border_width_left = int(1.5 * ui_scale); track.border_width_right = int(1.5 * ui_scale)
	track.border_color = Color(accent.r, accent.g, accent.b, 0.8) if is_on else Color(0.35, 0.25, 0.5)
	draw_style_box(track, sw_rect)
	var knob_x = sw_rect.position.x + sw_w - sw_h * 0.9 if is_on else sw_rect.position.x + sw_h * 0.05
	var knob_y = sw_rect.position.y + sw_h * 0.1
	var knob_sz = sw_h * 0.8
	draw_circle(Vector2(knob_x + knob_sz / 2.0, knob_y + knob_sz / 2.0), knob_sz / 2.0, Color.WHITE)
	draw_circle(Vector2(knob_x + knob_sz / 2.0, knob_y + knob_sz / 2.0), knob_sz / 2.0 - 2 * ui_scale,
		Color(0.95, 0.95, 1.0))

func _draw_settings_row_text(rect: Rect2, icon: String, label: String, value: String, accent: Color):
	_draw_panel(rect, Color(0.06, 0.03, 0.16, 0.9), 18, Color(0.35, 0.25, 0.65, 0.7))
	var ic = rect.position + Vector2(50 * ui_scale, rect.size.y / 2.0)
	var isz = 20 * ui_scale
	var icol = Color(0.85, 0.90, 1.0)
	match icon:
		"weather": _draw_icon_weather(ic, isz, icol)
		"lang": _draw_icon_globe(ic, isz, icol)
	draw_string(active_font(), Vector2(rect.position.x + 90 * ui_scale, rect.position.y + rect.size.y * 0.58),
		label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs(24), Color.WHITE)
	draw_string(active_font(), Vector2(rect.position.x + rect.size.x - 260 * ui_scale, rect.position.y + rect.size.y * 0.58),
		value, HORIZONTAL_ALIGNMENT_RIGHT, 200 * ui_scale, fs(22), accent)
	_draw_icon_chevron(Vector2(rect.position.x + rect.size.x - 40 * ui_scale,
		rect.position.y + rect.size.y / 2.0), 10 * ui_scale, Color(0.75, 0.7, 0.95, 0.85))

func handle_settings_click(pos):
	if not _try_ui_action(): return
	var r = _settings_row_rects()
	var hdr_y = to_screen(Vector2(0, 180)).y
	if Rect2(_safe_insets.x + 28 * ui_scale, hdr_y - 10 * ui_scale, 80 * ui_scale, 80 * ui_scale).has_point(pos):
		play_sfx(sfx_button); state = settings_return_state
		if state == State.MENU: _menu_enter_t = 0.0
		return
	if r["music"].has_point(pos):
		music_enabled = not music_enabled; save_settings()
		if music_enabled:
			current_music_state = 0
			update_music_for_state(2 if settings_return_state == State.PAUSED else 1)
		else: stop_music()
		play_sfx(sfx_button)
	elif r["sound"].has_point(pos):
		sound_enabled = not sound_enabled; save_settings(); play_sfx(sfx_button)
	elif r["vibro"].has_point(pos):
		vibration_enabled = not vibration_enabled; save_settings(); play_sfx(sfx_button)
		if vibration_enabled: vibrate(80)
	elif r["weather"].has_point(pos):
		weather_mode = (weather_mode + 1) % 3; save_settings(); _init_menu_blocks(); play_sfx(sfx_button)
	elif r["effects"].has_point(pos):
		reduce_effects = not reduce_effects
		if reduce_effects:
			screen_shake = 0.0; _shake_offset = Vector2.ZERO
			confetti.clear(); visual_effects.clear(); explosion_rings.clear()
			flash_alpha = 0.0; init_particles()
		_rebuild_bg_cache()
		save_settings(); play_sfx(sfx_button)
	elif r["lang"].has_point(pos):
		_next_language(); save_settings(); play_sfx(sfx_button)
	elif r["reset"].has_point(pos):
		high_score = 0; time_high = 0
		campaign_level = 1; campaign_max_unlocked = 1; level_stars_saved.clear()
		save_high_score(); save_time_high(); save_progress(); play_sfx(sfx_button)

func handle_menu_click(pos):
	if not _try_ui_action(): return
	var r = _menu_button_rects()
	if r["toggle_sound"].has_point(pos):
		play_sfx(sfx_button); sound_enabled = not sound_enabled; save_settings(); return
	if r["toggle_music"].has_point(pos):
		play_sfx(sfx_button); music_enabled = not music_enabled; save_settings()
		if music_enabled: current_music_state = 0; update_music_for_state(1)
		else: stop_music()
		return
	if r["toggle_settings"].has_point(pos):
		play_sfx(sfx_button); settings_return_state = State.MENU; state = State.SETTINGS; return
	if r["play"].has_point(pos): play_sfx(sfx_button); state = State.MODE_SELECT; return
	if r["settings"].has_point(pos): play_sfx(sfx_button); settings_return_state = State.MENU; state = State.SETTINGS; return
	if r["skins"].has_point(pos): play_sfx(sfx_button); state = State.SKINS; return
	if r["achievements"].has_point(pos):
		play_sfx(sfx_button); ach_scroll_px = 0.0; ach_velocity = 0.0; state = State.ACHIEVEMENTS; return
	if has_saved_game and r["continue"].has_point(pos):
		play_sfx(sfx_button); continue_game(); return

# ============================================================================
# SHIFT MODE
# ============================================================================

func _check_shift_trigger():
	if state != State.PLAYING: return
	if shift_in_progress: return
	if cleared_lines_total >= shift_lines_required:
		_start_shift_sequence()

func _start_shift_sequence():
	shift_in_progress = true
	shift_warning_count = 3
	shift_warning_timer = SHIFT_WARN_DURATION
	shift_direction = randi() % SHIFT_MAX_DIR
	dragging_piece = -1
	hint_visible = false
	hint_timer = 0.0
	play_sfx(sfx_button, 1.4)
	vibrate(60)
	trigger_flash(0.15)

func _apply_shift():
	var n = GRID_SIZE
	var new_grid = []
	for y in range(n):
		var row = []
		for x in range(n): row.append(null)
		new_grid.append(row)
	for y in range(n):
		for x in range(n):
			if grid[y][x] == null: continue
			var nx = x
			var ny = y
			match shift_direction:
				0: nx = x - 1
				1: nx = x + 1
				2: ny = y - 1
				3: ny = y + 1
			if SHIFT_WRAP:
				nx = ((nx % n) + n) % n
				ny = ((ny % n) + n) % n
				new_grid[ny][nx] = grid[y][x]
			else:
				if nx >= 0 and nx < n and ny >= 0 and ny < n:
					new_grid[ny][nx] = grid[y][x]
	grid = new_grid
	_mark_pieces_dirty()
	_recalc_density()
	for y in range(n):
		for x in range(n):
			if grid[y][x] != null:
				flash_cells.append({"x": x, "y": y, "timer": FLASH_DURATION, "max": FLASH_DURATION})
	var dir_names = ["LEFT", "RIGHT", "UP", "DOWN"]
	var dir_arrows = ["◄", "►", "▲", "▼"]
	spawn_combo_popup("SHIFT  " + dir_arrows[shift_direction] + " " + dir_names[shift_direction])
	trigger_shake(10.0)
	trigger_flash(0.35)
	play_sfx(sfx_bomb, 1.2)
	vibrate(120)
	shift_lines_required += SHIFT_LINES_STEP
	if not has_valid_moves():
		_shift_pending_gameover = true
	else:
		save_game_state()

func _check_shift_gameover():
	if not _shift_pending_gameover: return
	_shift_pending_gameover = false
	if not used_revive_this_game and game_mode != GameMode.CAMPAIGN:
		show_revive_screen()
	else:
		state = State.GAME_OVER
		play_sfx(sfx_gameover); vibrate(200); trigger_shake(18.0)
		if game_mode == GameMode.CLASSIC: save_high_score()
		if game_mode == GameMode.TIME: save_time_high()
		delete_game_state()
		stats.games_played += 1; games_played_session += 1
		check_achievements(); save_progress()
		if games_played_session % INTERSTITIAL_EVERY_N_GAMES == 0: show_interstitial_ad()
	queue_redraw()

# ============================================================================
# REVIVE
# ============================================================================

func show_revive_screen():
	revive_active = true; revive_shown = false
	revive_delay_timer = REVIVE_DELAY
	revive_appear = 0.0; revive_dim = 0.0
	revive_timer = REVIVE_TIMER
	revive_last_tick_sec = int(ceil(REVIVE_TIMER))
	revive_from_mode = game_mode
	state = State.REVIVE
	play_sfx(sfx_gameover, 1.0); queue_redraw()

func revive_decline():
	if not revive_active: return
	revive_active = false; revive_shown = false
	state = State.GAME_OVER
	_go_scatter_timer = 0.6
	vibrate(120)
	if game_mode == GameMode.CLASSIC: save_high_score()
	if game_mode == GameMode.TIME: save_time_high()
	delete_game_state()
	stats.games_played += 1; games_played_session += 1
	check_achievements(); save_progress()
	if games_played_session % INTERSTITIAL_EVERY_N_GAMES == 0: show_interstitial_ad()
	queue_redraw()

func revive_accept():
	if not revive_active: return
	revive_active = false; revive_shown = false
	show_rewarded_ad()

func handle_revive_click(pos):
	if not _try_ui_action(): return
	if not revive_shown: return
	var vp = get_viewport_rect().size
	var pw = min(vp.x * 0.88, 620 * ui_scale)
	var ph = min(vp.y * 0.62, 500 * ui_scale)
	var px = (vp.x - pw) / 2.0
	var py = (vp.y - ph) / 2.0
	var btn_h = min(vp.y * 0.09, 76 * ui_scale)
	var btn_w = pw - 60 * ui_scale
	var btn_x = px + 30 * ui_scale
	var btn_y = py + ph - btn_h - 62 * ui_scale
	if Rect2(btn_x, btn_y, btn_w, btn_h).has_point(pos):
		play_sfx(sfx_button); revive_accept(); return
	var sep_y = btn_y + btn_h + 14 * ui_scale
	var no_h = 40 * ui_scale
	var no_w = pw * 0.55
	var no_x = px + (pw - no_w) / 2.0
	var no_y = sep_y + 10 * ui_scale
	if Rect2(no_x, no_y, no_w, no_h).has_point(pos):
		play_sfx(sfx_button); revive_decline(); return

# ============================================================================
# PAUSE / BUTTON / GAME OVER
# ============================================================================

func draw_pause_overlay():
	var vp = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.02, 0.01, 0.08, 0.58))
	var pw = 640 * ui_scale; var ph = 600 * ui_scale
	var px = (vp.x - pw) / 2.0; var py = (vp.y - ph) / 2.0
	var pr = Rect2(px, py, pw, ph)
	_draw_glow(pr, N_PURPLE, 5, 6.0, 0.18)
	var panel = StyleBoxFlat.new()
	panel.bg_color = Color(0.09, 0.04, 0.22, 0.92)
	panel.set_corner_radius_all(int(36 * ui_scale))
	panel.border_width_top = int(2.5 * ui_scale); panel.border_width_bottom = int(2.5 * ui_scale)
	panel.border_width_left = int(2.5 * ui_scale); panel.border_width_right = int(2.5 * ui_scale)
	panel.border_color = C_BORDER_HI
	draw_style_box(panel, pr)
	var ty = py + fs(110)
	for i in range(4):
		var off = i * 2 * ui_scale
		draw_string(active_font(), Vector2(px - off, ty - off),
			tr_("pause_title"), HORIZONTAL_ALIGNMENT_CENTER, pw, fs(72),
			Color(1.0, 0.35, 0.95, 0.55 - i * 0.12))
	draw_string(active_font(), Vector2(px, ty), tr_("pause_title"),
		HORIZONTAL_ALIGNMENT_CENTER, pw, fs(72), Color(1.0, 0.98, 1.0))
	var bw = pw - 100 * ui_scale; var bh = 92 * ui_scale
	var bx = px + 50 * ui_scale; var sy = py + 230 * ui_scale; var gap = 20 * ui_scale
	_draw_pause_button(Rect2(bx, sy, bw, bh), "play", tr_("resume"), N_GREEN)
	_draw_pause_button(Rect2(bx, sy + (bh + gap), bw, bh), "home", tr_("main_menu"), N_PURPLE)
	_draw_pause_button(Rect2(bx, sy + (bh + gap) * 2, bw, bh), "gear", tr_("settings"), N_BLUE)

func _draw_pause_button(rect: Rect2, icon_name: String, label: String, accent: Color):
	_draw_btn_3d(rect, accent, Color(accent.r * 0.35, accent.g * 0.35, accent.b * 0.35))
	var ic = Vector2(rect.position.x + 60 * ui_scale, rect.position.y + rect.size.y * 0.44)
	var isz = 22 * ui_scale
	match icon_name:
		"play": _draw_icon_play(ic, isz, Color.WHITE)
		"home": _draw_icon_home(ic, isz, Color.WHITE)
		"gear": _draw_icon_gear(ic, isz, Color.WHITE)
	draw_string(active_font(), Vector2(rect.position.x + 50 * ui_scale, rect.position.y + rect.size.y * 0.66),
		label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 100 * ui_scale, fs(30), Color.WHITE)

func handle_pause_click(pos):
	if not _try_ui_action(): return
	var vp = get_viewport_rect().size
	var pw = 640 * ui_scale; var ph = 600 * ui_scale
	var px = (vp.x - pw) / 2.0; var py = (vp.y - ph) / 2.0
	var bw = pw - 100 * ui_scale; var bh = 92 * ui_scale
	var bx = px + 50 * ui_scale; var sy = py + 230 * ui_scale; var gap = 20 * ui_scale
	if Rect2(bx, sy, bw, bh).has_point(pos): play_sfx(sfx_button); resume_game()
	elif Rect2(bx, sy + (bh + gap), bw, bh).has_point(pos):
		play_sfx(sfx_button); save_game_state(); state = State.MENU; has_saved_game = true; _menu_enter_t = 0.0
	elif Rect2(bx, sy + (bh + gap) * 2, bw, bh).has_point(pos):
		play_sfx(sfx_button); settings_return_state = State.PAUSED; state = State.SETTINGS

func pause_game():
	state = State.PAUSED
	if music_player != null and music_player.playing: music_player.stream_paused = true
	save_game_state(); queue_redraw()

func resume_game():
	state = State.PLAYING
	if music_player != null: music_player.stream_paused = false
	queue_redraw()

func restart_current_mode():
	match game_mode:
		GameMode.CLASSIC: start_classic_game()
		GameMode.TIME: start_time_game()
		GameMode.CAMPAIGN: start_campaign_level(campaign_level)

func draw_button(ref_rect, text, enabled):
	var rect = to_screen_rect(ref_rect)
	var top_col = N_BLUE if enabled else Color(0.18, 0.15, 0.25)
	var sh_col = N_BLUE_SH if enabled else Color(0.08, 0.05, 0.12)
	_draw_btn_3d(rect, top_col, sh_col)
	var max_w = rect.size.x - 40 * ui_scale
	var txt_fs = fs(24)
	while txt_fs > 12 and active_font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, txt_fs).x > max_w:
		txt_fs -= 1
	draw_string(active_font(), rect.position + Vector2(0, rect.size.y * 0.5 + txt_fs * 0.35),
		text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, txt_fs,
		Color.WHITE if enabled else Color(0.5, 0.5, 0.55))

func draw_beveled_block(rect: Rect2, color: Color):
	_render_block_styled(rect, color, _current_skin(), 1.0)

func draw_game_over():
	var vp = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.02, 0.01, 0.08, 0.82))
	var title = tr_("game_over_title")
	if game_mode == GameMode.CAMPAIGN: title = tr_("win") if campaign_won else tr_("lose")
	var title_y = vp.y * 0.18
	var title_fs = clamp(int(vp.y * 0.065), 36, 78)
	for i in range(6, 0, -1):
		draw_string(active_font(), Vector2(0, title_y + i * 1.3 * ui_scale), title,
			HORIZONTAL_ALIGNMENT_CENTER, vp.x, title_fs, Color(0.55, 0.06, 0.02, 0.95))
	for i in range(3, 0, -1):
		draw_string(active_font(), Vector2(0, title_y - i * 0.8 * ui_scale), title,
			HORIZONTAL_ALIGNMENT_CENTER, vp.x, title_fs, Color(1.0, 0.85, 0.25, 0.45))
	draw_string(active_font(), Vector2(0, title_y), title,
		HORIZONTAL_ALIGNMENT_CENTER, vp.x, title_fs, Color(1.0, 0.55, 0.10))
	var pw = min(vp.x * 0.85, 640 * ui_scale)
	var ph = min(vp.y * 0.30, 320 * ui_scale)
	var px = (vp.x - pw) / 2.0
	var py = vp.y * 0.30
	var pr = Rect2(px, py, pw, ph)
	_draw_glow(pr, N_MAGENTA, 4, 6.0, 0.18)
	_draw_panel(pr, Color(0.09, 0.04, 0.22, 0.95), 30, C_BORDER_HI)
	draw_string(active_font(), Vector2(px, py + ph * 0.20), tr_("score"),
		HORIZONTAL_ALIGNMENT_CENTER, pw, fs(24), Color(0.78, 0.85, 1.0))
	var score_y = py + ph * 0.55
	var score_fs = fs(72)
	draw_string(active_font(), Vector2(0, score_y + 3 * ui_scale),
		str(score), HORIZONTAL_ALIGNMENT_CENTER, vp.x, score_fs, Color(0.10, 0.02, 0.30, 0.9))
	draw_string(active_font(), Vector2(0, score_y),
		str(score), HORIZONTAL_ALIGNMENT_CENTER, vp.x, score_fs, Color.WHITE)
	var rec_val = time_high if game_mode == GameMode.TIME else high_score
	var best_y = py + ph * 0.85
	var best_text = tr_("best") + " " + str(rec_val)
	var best_fs = fs(24)
	var text_w = active_font().get_string_size(best_text, HORIZONTAL_ALIGNMENT_LEFT, -1, best_fs).x
	var group_x = (vp.x - (20 * ui_scale + 14 * ui_scale + text_w)) / 2.0
	_draw_icon_crown(Vector2(group_x + 10 * ui_scale, best_y - best_fs * 0.25), 12 * ui_scale, N_YELLOW)
	draw_string(active_font(), Vector2(group_x + 34 * ui_scale, best_y),
		best_text, HORIZONTAL_ALIGNMENT_LEFT, -1, best_fs, Color(1.0, 0.88, 0.30))
	if game_mode != GameMode.CAMPAIGN and score > 0 and score >= rec_val:
		var pulse = 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.006)
		var nr_w = min(vp.x * 0.7, 500 * ui_scale)
		var nr_h = min(vp.y * 0.05, 44 * ui_scale)
		var nr_x = (vp.x - nr_w) / 2.0
		var nr_y = py + ph + 12 * ui_scale
		_draw_glow(Rect2(nr_x, nr_y, nr_w, nr_h), N_YELLOW, 3, 5.0, 0.28)
		_draw_panel(Rect2(nr_x, nr_y, nr_w, nr_h), Color(0.30, 0.20, 0.02, 0.95), 20, N_YELLOW)
		draw_string(active_font(), Vector2(nr_x, nr_y + nr_h * 0.70),
			tr_("new_record"), HORIZONTAL_ALIGNMENT_CENTER, nr_w, fs(20), Color(1.0, 0.95, 0.45, pulse))
	var bottom_safe = _safe_insets.w
	var btn_w = min(vp.x * 0.75, 540 * ui_scale)
	var btn_h = min(vp.y * 0.075, 78 * ui_scale)
	var bx = (vp.x - btn_w) / 2.0
	var by_start = vp.y - bottom_safe - 30 * ui_scale - btn_h * 2 - 16 * ui_scale
	if game_mode == GameMode.CAMPAIGN:
		if campaign_won:
			for i in range(3):
				var sx = vp.x / 2.0 + (i - 1) * 70 * ui_scale
				var col = N_YELLOW if i < level_stars_earned else Color(0.3, 0.25, 0.4)
				_draw_icon_star(Vector2(sx, by_start - 30 * ui_scale), 22 * ui_scale, col)
			_draw_btn_3d(Rect2(bx, by_start, btn_w, btn_h), N_GREEN, N_GREEN_SH)
			_draw_icon_check(Vector2(bx + 70 * ui_scale, by_start + btn_h * 0.44), 16 * ui_scale, Color.WHITE)
			draw_string(active_font(), Vector2(bx + 40 * ui_scale, by_start + btn_h * 0.66),
				tr_("next_level"), HORIZONTAL_ALIGNMENT_CENTER, btn_w - 80 * ui_scale, fs(26), Color.WHITE)
		else:
			_draw_btn_3d(Rect2(bx, by_start, btn_w, btn_h), N_GREEN, N_GREEN_SH)
			_draw_icon_restart(Vector2(bx + 70 * ui_scale, by_start + btn_h * 0.44), 18 * ui_scale, Color.WHITE)
			draw_string(active_font(), Vector2(bx + 40 * ui_scale, by_start + btn_h * 0.66),
				tr_("retry"), HORIZONTAL_ALIGNMENT_CENTER, btn_w - 80 * ui_scale, fs(26), Color.WHITE)
		var r2 = Rect2(bx, by_start + btn_h + 16 * ui_scale, btn_w, btn_h)
		_draw_btn_3d(r2, N_PURPLE, N_PURPLE_SH)
		_draw_icon_home(Vector2(r2.position.x + 70 * ui_scale, r2.position.y + btn_h * 0.44), 18 * ui_scale, Color.WHITE)
		draw_string(active_font(), Vector2(r2.position.x + 40 * ui_scale, r2.position.y + btn_h * 0.66),
			tr_("main_menu"), HORIZONTAL_ALIGNMENT_CENTER, btn_w - 80 * ui_scale, fs(26), Color.WHITE)
	else:
		var r1 = Rect2(bx, by_start, btn_w, btn_h)
		_draw_btn_3d(r1, N_GREEN, N_GREEN_SH)
		_draw_icon_restart(Vector2(r1.position.x + 70 * ui_scale, r1.position.y + btn_h * 0.44), 20 * ui_scale, Color.WHITE)
		draw_string(active_font(), Vector2(r1.position.x + 40 * ui_scale, r1.position.y + btn_h * 0.66),
			tr_("restart"), HORIZONTAL_ALIGNMENT_CENTER, btn_w - 80 * ui_scale, fs(28), Color.WHITE)
		var r2b = Rect2(bx, by_start + btn_h + 16 * ui_scale, btn_w, btn_h)
		_draw_btn_3d(r2b, N_PURPLE, N_PURPLE_SH)
		_draw_icon_home(Vector2(r2b.position.x + 70 * ui_scale, r2b.position.y + btn_h * 0.44), 18 * ui_scale, Color.WHITE)
		draw_string(active_font(), Vector2(r2b.position.x + 40 * ui_scale, r2b.position.y + btn_h * 0.66),
			tr_("main_menu"), HORIZONTAL_ALIGNMENT_CENTER, btn_w - 80 * ui_scale, fs(26), Color.WHITE)
	draw_confetti(); draw_flash()

func handle_game_over_click(pos):
	if not _try_ui_action(): return
	var vp = get_viewport_rect().size
	var bottom_safe = _safe_insets.w
	var btn_w = min(vp.x * 0.75, 540 * ui_scale)
	var btn_h = min(vp.y * 0.075, 78 * ui_scale)
	var bx = (vp.x - btn_w) / 2.0
	var by_start = vp.y - bottom_safe - 30 * ui_scale - btn_h * 2 - 16 * ui_scale
	if game_mode == GameMode.CAMPAIGN:
		if campaign_won:
			if Rect2(bx, by_start, btn_w, btn_h).has_point(pos):
				play_sfx(sfx_button); campaign_level = min(999, campaign_level + 1); start_campaign_level(campaign_level); return
		else:
			if Rect2(bx, by_start, btn_w, btn_h).has_point(pos):
				play_sfx(sfx_button); start_campaign_level(campaign_level); return
		if Rect2(bx, by_start + btn_h + 16 * ui_scale, btn_w, btn_h).has_point(pos):
			play_sfx(sfx_button); state = State.CAMPAIGN_MAP; return
		return
	if Rect2(bx, by_start, btn_w, btn_h).has_point(pos):
		play_sfx(sfx_button); restart_current_mode(); return
	if Rect2(bx, by_start + btn_h + 16 * ui_scale, btn_w, btn_h).has_point(pos):
		play_sfx(sfx_button); state = State.MENU; _menu_enter_t = 0.0; return

# ============================================================================
# UI INPUT PROTECTION
# ============================================================================

func _try_ui_action() -> bool:
	var now = Time.get_ticks_msec() * 0.001
	if now - _last_ui_action_time < UI_ACTION_COOLDOWN:
		return false
	_last_ui_action_time = now
	return true

# ============================================================================
# INPUT
# ============================================================================

func _input(event):
	if not audio_started and (event is InputEventMouseButton or event is InputEventScreenTouch):
		if event.pressed:
			audio_started = true; current_music_state = 0; update_music_for_state(1)
	if OS.has_feature("mobile") and (event is InputEventMouseButton or event is InputEventMouseMotion): return
	if state == State.ACHIEVEMENTS and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: ach_velocity = 1800.0; return
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP: ach_velocity = -1800.0; return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE: _handle_back_button(); return
		elif event.keycode == KEY_R and state == State.GAME_OVER: restart_current_mode(); return
		elif event.keycode == KEY_H and state == State.PLAYING: _show_hint(); return
	if event is InputEventScreenTouch:
		if event.pressed:
			if _active_touch_index != -1: return
			_active_touch_index = event.index
			_touch_press_pos = event.position
			_touch_started_drag = false
			_touch_time = Time.get_ticks_msec() / 1000.0
			if state == State.REVIVE: handle_revive_click(event.position); return
			_handle_press_mobile(event.position)
		else:
			if event.index == _active_touch_index:
				if _touch_started_drag:
					handle_release(event.position)
				else:
					# Только тап-в-точку — и только если палец не съехал
					var moved = event.position.distance_to(_touch_press_pos)
					if moved <= TOUCH_DRAG_THRESHOLD * ui_scale * 2.0:
						if state != State.REVIVE:
							handle_press(event.position)
							if state == State.PLAYING:
								handle_release(event.position)
				_active_touch_index = -1
				_touch_started_drag = false
		return
	if event is InputEventScreenDrag:
		if event.index != _active_touch_index: return
		mouse_pos = event.position
		if not _touch_started_drag:
			if event.position.distance_to(_touch_press_pos) > TOUCH_DRAG_THRESHOLD * ui_scale:
				_touch_started_drag = true
				if state == State.PLAYING and not shift_in_progress:
					var result = get_piece_at_position(_touch_press_pos)
					if result.index != -1:
						dragging_piece = result.index
						drag_offset = result.offset
						hint_timer = 0.0; hint_visible = false
		elif state == State.PLAYING and dragging_piece != -1: queue_redraw()
		elif state == State.ACHIEVEMENTS and ach_dragging:
			var dy = event.position.y - ach_drag_start_y
			ach_scroll_px = clamp(ach_drag_start_scroll - dy / ui_scale, 0.0, _ach_max_scroll())
			var now = Time.get_ticks_msec() / 1000.0
			var dt = now - ach_last_move_time
			if dt > 0.001: ach_velocity = (ach_last_move_y - event.position.y) / dt / ui_scale
			ach_last_move_y = event.position.y; ach_last_move_time = now
			queue_redraw()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed: handle_press(event.position)
		else: handle_release(event.position)
		return
	if event is InputEventMouseMotion: handle_move(event.position); return

func _handle_press_mobile(pos: Vector2):
	if state == State.PLAYING: mouse_pos = pos
	else: handle_press(pos)

func handle_press(pos):
	if shift_in_progress: return
	if state == State.LOADING:
		if loading_elapsed < LOADING_MIN_TIME: loading_elapsed = min(LOADING_MIN_TIME, loading_elapsed + 0.6)
		return
	if state == State.TUTORIAL:
		var vp = get_viewport_rect().size
		var br = Rect2(vp.x * 0.5 - 250 * ui_scale, vp.y * 0.55 + 320 * ui_scale, 500 * ui_scale, 65 * ui_scale)
		if br.has_point(pos): advance_tutorial()
		return
	match state:
		State.MENU: handle_menu_click(pos)
		State.MODE_SELECT: handle_mode_select_click(pos)
		State.SKINS: handle_skins_click(pos)
		State.ACHIEVEMENTS: handle_achievements_click(pos)
		State.PAUSED: handle_pause_click(pos)
		State.SETTINGS: handle_settings_click(pos)
		State.GAME_OVER: handle_game_over_click(pos)
		State.REVIVE: handle_revive_click(pos)
		State.CAMPAIGN_MAP: handle_campaign_click(pos)
		State.PLAYING:
			mouse_pos = pos
			var pause_rect = Rect2(_safe_insets.x + 30 * ui_scale, _safe_insets.y + 60 * ui_scale, 80 * ui_scale, 80 * ui_scale)
			if pause_rect.has_point(pos): pause_game()
			else:
				var gr = Rect2(get_viewport_rect().size.x - _safe_insets.z - 110 * ui_scale,
					_safe_insets.y + 60 * ui_scale, 80 * ui_scale, 80 * ui_scale)
				if gr.has_point(pos): settings_return_state = State.PAUSED; state = State.SETTINGS
				elif hint_btn_rect.has_point(pos): play_sfx(sfx_button); _show_hint()
				else:
					if not OS.has_feature("mobile"):
						var result = get_piece_at_position(pos)
						dragging_piece = result.index
						drag_offset = result.offset
						hint_timer = 0.0; hint_visible = false
	queue_redraw()

func handle_release(pos):
	mouse_pos = pos
	if shift_in_progress:
		dragging_piece = -1
		drag_trail.clear()
		return
	if state == State.ACHIEVEMENTS and ach_dragging:
		ach_dragging = false; ach_velocity = clamp(ach_velocity, -3000.0, 3000.0); return
	if state == State.PLAYING and dragging_piece != -1:
		place_piece(pos, dragging_piece)
		dragging_piece = -1; drag_trail.clear()
	queue_redraw()

func handle_move(pos):
	mouse_pos = pos
	if state == State.ACHIEVEMENTS and ach_dragging:
		var dy = pos.y - ach_drag_start_y
		ach_scroll_px = clamp(ach_drag_start_scroll - dy / ui_scale, 0.0, _ach_max_scroll())
		var now = Time.get_ticks_msec() / 1000.0
		var dt = now - ach_last_move_time
		if dt > 0.001: ach_velocity = (ach_last_move_y - pos.y) / dt / ui_scale
		ach_last_move_y = pos.y; ach_last_move_time = now
		queue_redraw(); return
	if state == State.PLAYING and dragging_piece != -1: queue_redraw()

func get_piece_at_position(pos):
	if pieces.is_empty(): return {"index": -1, "offset": Vector2.ZERO}
	for i in range(pieces.size()):
		var piece = pieces[i]
		if piece["blocks"].is_empty(): continue
		var layout = get_piece_tray_layout(i)
		if layout["bounds"].has_point(pos): return {"index": i, "offset": pos - layout["origin"]}
	return {"index": -1, "offset": Vector2.ZERO}

# ============================================================================
# SIMULATION
# ============================================================================

func _sim_can_place(sim_grid: Array, blocks: Array, sx: int, sy: int) -> bool:
	for b in blocks:
		var x = sx + b.x; var y = sy + b.y
		if x < 0 or x >= GRID_SIZE or y < 0 or y >= GRID_SIZE: return false
		if sim_grid[y][x] != null: return false
	return true

func _sim_has_spot(sim_grid: Array, blocks: Array) -> bool:
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if _sim_can_place(sim_grid, blocks, x, y): return true
	return false

func _sim_score_move(sim_grid: Array, blocks: Array, sx: int, sy: int) -> float:
	var placed := {}
	for b in blocks: placed[Vector2i(sx + b.x, sy + b.y)] = true
	var sc = 0.0
	for y in range(GRID_SIZE):
		var fl = 0
		for x in range(GRID_SIZE):
			if sim_grid[y][x] != null or placed.has(Vector2i(x, y)): fl += 1
		if fl == GRID_SIZE: sc += 1000.0
		elif fl == GRID_SIZE - 1: sc += 50.0
	for x in range(GRID_SIZE):
		var fl = 0
		for y in range(GRID_SIZE):
			if sim_grid[y][x] != null or placed.has(Vector2i(x, y)): fl += 1
		if fl == GRID_SIZE: sc += 1000.0
		elif fl == GRID_SIZE - 1: sc += 50.0
	for b in blocks:
		var px = sx + b.x; var py = sy + b.y
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if dx == 0 and dy == 0: continue
				var nx = px + dx; var ny = py + dy
				if nx >= 0 and nx < GRID_SIZE and ny >= 0 and ny < GRID_SIZE:
					if sim_grid[ny][nx] != null: sc += 3.0
	return sc

func _sim_find_best_position(sim_grid: Array, blocks: Array) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_score := -1000000.0
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if not _sim_can_place(sim_grid, blocks, x, y): continue
			var sc = _sim_score_move(sim_grid, blocks, x, y)
			if sc > best_score: best_score = sc; best = Vector2i(x, y)
	return best

func _simulate_three_moves(candidate: Array) -> bool:
	var sim = []
	for y in range(GRID_SIZE):
		var row = []
		for x in range(GRID_SIZE): row.append(grid[y][x])
		sim.append(row)
	for p in candidate:
		if p["blocks"].is_empty(): continue
		var pos = _sim_find_best_position(sim, p["blocks"])
		if pos.x == -1: return false
		for b in p["blocks"]: sim[pos.y + b.y][pos.x + b.x] = p["color"]
	for idx in SMALL_SHAPE_IDX:
		if _sim_has_spot(sim, ALL_SHAPES[idx]): return true
	return false

# ============================================================================
# SMART PIECE GENERATION
# ============================================================================

func _difficulty_bias() -> float:
	var s = float(score)
	if s < 800.0: return s / 800.0 * 0.25
	elif s < 3000.0: return 0.25 + (s - 800.0) / 2200.0 * 0.35
	elif s < 8000.0: return 0.60 + (s - 3000.0) / 5000.0 * 0.30
	return min(1.0, 0.90 + (s - 8000.0) / 20000.0 * 0.10)

func _pick_shape_idx_smart(rescue: bool) -> int:
	if rescue: return _pick_small_shape_idx()
	var bias = _difficulty_bias()
	var roll = randf()
	if roll > bias * 0.6: return SMALL_SHAPE_IDX[randi() % SMALL_SHAPE_IDX.size()]
	if roll > bias * 0.35:
		var med = [1, 2, 5, 6, 11, 12, 13, 14, 15, 16, 17, 18, 22, 23]
		return med[randi() % med.size()]
	var big = [3, 4, 7, 8, 10, 19, 20, 21, 24, 25, 26]
	return big[randi() % big.size()]

func _make_smart_piece(force_small: bool = false) -> Dictionary:
	if not force_small:
		var roll = randf()
		if field_density > 0.45 and roll < BOMB_CHANCE and _pieces_since_bomb >= BOMB_MIN_INTERVAL:
			_pieces_since_bomb = 0
			return {"blocks": [Vector2i(0, 0)], "color": BOMB_COLOR, "type": "bomb"}
		var near_line = false
		for y in range(GRID_SIZE):
			var fl = 0
			for x in range(GRID_SIZE):
				if grid[y][x] != null: fl += 1
			if fl >= GRID_SIZE - 2: near_line = true; break
		if not near_line:
			for x in range(GRID_SIZE):
				var fl = 0
				for y in range(GRID_SIZE):
					if grid[y][x] != null: fl += 1
				if fl >= GRID_SIZE - 2: near_line = true; break
		if (near_line or field_density > 0.60) \
				and roll < BOMB_CHANCE + LINE_CLEAR_CHANCE \
				and _pieces_since_line >= LINE_MIN_INTERVAL:
			_pieces_since_line = 0
			return {"blocks": SPECIAL_SHAPES[randi() % SPECIAL_SHAPES.size()],
				"color": LINE_CLEAR_COLOR, "type": "line_clear"}
	_pieces_since_bomb += 1
	_pieces_since_line += 1
	var idx = _pick_shape_idx_smart(force_small)
	var attempts = 0
	while attempts < 8 and _last_piece_shapes.size() >= 2:
		var same_count = 0
		for s in _last_piece_shapes:
			if s == idx: same_count += 1
		if same_count < 2: break
		idx = randi() % ALL_SHAPES.size()
		attempts += 1
	var col = _pick_fresh_color()
	return {"blocks": ALL_SHAPES[idx], "color": col, "type": "normal"}

func _has_small_piece(piece_set: Array) -> bool:
	for p in piece_set:
		if _shape_index_of(p) in SMALL_SHAPE_IDX: return true
	return false

func _count_special(piece_set: Array) -> int:
	var c = 0
	for p in piece_set:
		if p["type"] == "bomb" or p["type"] == "line_clear": c += 1
	return c

func _count_color(piece_set: Array, col: Color) -> int:
	var c = 0
	for p in piece_set:
		if p["color"].is_equal_approx(col): c += 1
	return c

func _update_history(piece_set: Array):
	_last_piece_shapes.clear(); _last_piece_colors.clear()
	for p in piece_set:
		_last_piece_shapes.append(_shape_index_of(p))
		_last_piece_colors.append(p["color"])

func generate_new_pieces():
	_recalc_density()
	var rescue_mode = field_density >= DENSITY_RESCUE
	var emergency_mode = field_density >= DENSITY_EMERGENCY
	var candidate: Array = []
	var attempts = 0
	var max_attempts = 30
	while attempts < max_attempts:
		candidate.clear()
		if emergency_mode:
			candidate.append({"blocks": [Vector2i(0, 0)], "color": BOMB_COLOR, "type": "bomb"})
			candidate.append(_make_smart_piece(true))
			candidate.append(_make_smart_piece(true))
		elif rescue_mode:
			for i in range(3): candidate.append(_make_smart_piece(true))
		else:
			for i in range(3): candidate.append(_make_smart_piece(false))
			if not _has_small_piece(candidate):
				candidate[randi() % 3] = _make_smart_piece(true)
			var sp = _count_special(candidate)
			if sp > 1:
				var repl = 0
				for i in range(3):
					if repl >= sp - 1: break
					if candidate[i]["type"] != "normal":
						candidate[i] = _make_smart_piece(true); repl += 1
			for i in range(3):
				if candidate[i]["type"] != "normal": continue
				if _count_color(candidate, candidate[i]["color"]) > 2:
					candidate[i] = _make_smart_piece(true)
		pieces = candidate.duplicate(true)
		_mark_pieces_dirty()
		if not has_valid_moves(): attempts += 1; continue
		if _simulate_three_moves(candidate): break
		attempts += 1
	if not has_valid_moves():
		pieces = []
		for i in range(3):
			pieces.append({"blocks": [Vector2i(0, 0)], "color": _pick_fresh_color(), "type": "normal"})
	_update_history(pieces)
	for i in range(piece_spawn_timers.size()): piece_spawn_timers[i] = PIECE_SPAWN_DURATION
	for i in range(_piece_spawn_delay.size()): _piece_spawn_delay[i] = PIECE_SPAWN_STAGGER * i
	_mark_pieces_dirty()

# Алиасы под ТЗ
func has_valid_move_for_shape(shape) -> bool:
	if shape is Dictionary:
		return piece_has_spot(shape)
	return _blocks_have_spot(shape)

func has_any_valid_move() -> bool:
	return has_valid_moves()

func _blocks_have_spot(blocks: Array) -> bool:
	if blocks.is_empty(): return true
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if can_place_piece(blocks, x, y): return true
	return false

# ============================================================================
# GAME LOGIC
# ============================================================================

func place_piece(_pos, piece_index):
	var piece = pieces[piece_index]
	if piece["blocks"].is_empty(): return
	var origin_pixel = get_drag_origin_pixel()
	var grid_offset = origin_pixel - get_shaked_grid_pos()
	var sx = round(grid_offset.x / cell_size); var sy = round(grid_offset.y / cell_size)
	if not can_place_piece(piece["blocks"], sx, sy): return
	var vpb = 0
	for yy in range(GRID_SIZE):
		for xx in range(GRID_SIZE):
			if can_place_piece(piece["blocks"], xx, yy): vpb += 1
	for block in piece["blocks"]:
		var x = sx + block.x; var y = sy + block.y
		grid[y][x] = piece["color"]
		pop_cells.append({"x": x, "y": y,
			"timer": POP_DURATION * 1.8, "max": POP_DURATION * 1.8, "squash": true})
		spawn_effect_burst(get_shaked_grid_pos() + Vector2(x + 0.5, y + 0.5) * cell_size, piece["color"], 3)
	score += piece["blocks"].size() * 10
	var center_world = get_shaked_grid_pos() + Vector2(sx + 0.5, sy + 0.5) * cell_size
	score_popups.append({"pos": center_world, "text": "+" + str(piece["blocks"].size() * 10),
		"timer": 0.9, "max": 0.9, "color": Color.WHITE})
	play_sfx(sfx_place); vibrate(35); stats.play_first = 1
	var placed_cells := {}
	for block in piece["blocks"]: placed_cells[Vector2i(sx + block.x, sy + block.y)] = true
	row_glow_cells.clear()
	var almost = false
	for y in range(GRID_SIZE):
		var fl = 0
		for x in range(GRID_SIZE):
			if grid[y][x] != null or placed_cells.has(Vector2i(x, y)): fl += 1
		if fl == GRID_SIZE - 1:
			almost = true
			for x in range(GRID_SIZE): row_glow_cells.append({"x": x, "y": y, "t": 1.2, "max": 1.2})
	if not almost:
		for x in range(GRID_SIZE):
			var fl = 0
			for y in range(GRID_SIZE):
				if grid[y][x] != null or placed_cells.has(Vector2i(x, y)): fl += 1
			if fl == GRID_SIZE - 1:
				almost = true
				for y in range(GRID_SIZE): row_glow_cells.append({"x": x, "y": y, "t": 1.2, "max": 1.2})
	if almost: play_sfx(sfx_place, 1.9)
	var extra_lines = apply_special_effect(piece, sx, sy)
	pieces[piece_index] = {"blocks": [], "color": Color.WHITE, "type": "normal"}
	_mark_pieces_dirty()
	var lines_cleared = clear_lines()
	apply_combo(lines_cleared + extra_lines)
	_recalc_density()
	if vpb == 1 and (lines_cleared + extra_lines) > 0:
		stats.comeback = 1; check_achievements()
	if lines_cleared + extra_lines >= 5: stats.five_clear = 1
	elif lines_cleared + extra_lines >= 3: stats.triple_clear = 1
	if game_mode == GameMode.TIME and lines_cleared + extra_lines > 0:
		time_left = min(TIME_DURATION, time_left + TIME_PER_LINE * (lines_cleared + extra_lines))
	if game_mode == GameMode.CLASSIC and score > high_score:
		high_score = score; stats.best_score = max(stats.best_score, score); save_high_score()
	elif game_mode == GameMode.TIME and score > time_high:
		time_high = score; stats.best_time = max(stats.best_time, score); save_time_high()
	var any_block = false
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if grid[y][x] != null: any_block = true; break
		if any_block: break
	if not any_block and score > 0: stats.perfect_clear = 1
	if game_mode == GameMode.CAMPAIGN:
		campaign_moves_left -= 1
		var goal = (lvl_crystals >= goal_crystals) and (lvl_diamonds >= goal_diamonds) and (lvl_stars >= goal_stars)
		if goal:
			campaign_won = true
			var mp = float(campaign_moves_left) / float(campaign_moves_total)
			if mp >= 0.70: level_stars_earned = 3
			elif mp >= 0.40: level_stars_earned = 2
			else: level_stars_earned = 1
			var prev = level_stars_saved.get(campaign_level, 0)
			if level_stars_earned > prev: level_stars_saved[campaign_level] = level_stars_earned
			if campaign_level + 1 > campaign_max_unlocked: campaign_max_unlocked = campaign_level + 1
			stats.campaign_max = max(stats.campaign_max, campaign_max_unlocked)
			save_progress(); check_achievements()
			state = State.GAME_OVER
			play_sfx(sfx_combo, 1.4); trigger_flash(0.4); spawn_confetti(); vibrate(150)
			games_played_session += 1; stats.games_played += 1
			save_progress(); queue_redraw(); return
		elif campaign_moves_left <= 0:
			campaign_won = false
			state = State.GAME_OVER
			play_sfx(sfx_gameover); vibrate(200); trigger_shake(15.0)
			stats.games_played += 1; games_played_session += 1
			check_achievements(); save_progress()
			queue_redraw(); return
	var all_used = true
	for p in pieces:
		if not p["blocks"].is_empty(): all_used = false
	if all_used: generate_new_pieces()
	if not has_valid_moves():
		if not used_revive_this_game and game_mode != GameMode.CAMPAIGN:
			show_revive_screen()
		else:
			state = State.GAME_OVER
			play_sfx(sfx_gameover); vibrate(200); trigger_shake(18.0)
			if game_mode == GameMode.CLASSIC: save_high_score()
			if game_mode == GameMode.TIME: save_time_high()
			delete_game_state()
			stats.games_played += 1; games_played_session += 1
			check_achievements(); save_progress()
			if games_played_session % INTERSTITIAL_EVERY_N_GAMES == 0: show_interstitial_ad()
	else: save_game_state()
	queue_redraw()

func can_place_piece(blocks, sx, sy):
	for block in blocks:
		var x = sx + block.x; var y = sy + block.y
		if x < 0 or x >= GRID_SIZE: return false
		if y < 0 or y >= GRID_SIZE: return false
		if grid[y][x] != null: return false
	return true

func piece_has_spot(piece) -> bool:
	if piece["blocks"].is_empty(): return true
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if can_place_piece(piece["blocks"], x, y): return true
	return false

func has_valid_moves():
	for i in range(pieces.size()):
		var piece = pieces[i]
		if piece["blocks"].is_empty(): continue
		if piece_has_spot(piece): return true
	return false

func clear_lines():
	var full_rows: Array = []
	var full_cols: Array = []
	for y in range(GRID_SIZE):
		if is_row_full(y): full_rows.append(y)
	for x in range(GRID_SIZE):
		if is_column_full(x): full_cols.append(x)
	var lc = full_rows.size() + full_cols.size()
	for y in full_rows: spawn_flash_row(y); clear_row(y)
	for x in full_cols: spawn_flash_col(x); clear_column(x)
	if lc > 0:
		stats.total_lines += lc
		trigger_flash(0.35 + min(0.15, lc * 0.05))
		cleared_lines_total += lc
		_check_shift_trigger()
	return lc

func apply_special_effect(piece, sx, sy):
	var type = piece.get("type", "normal")
	var el = 0
	if type == "bomb":
		for block in piece["blocks"]: explode_at(sx + block.x, sy + block.y)
		play_sfx(sfx_bomb); trigger_shake(12.0); stats.total_bombs += 1
	elif type == "line_clear":
		var rows = {}; var cols = {}
		for block in piece["blocks"]:
			rows[sy + block.y] = true; cols[sx + block.x] = true
		for y in rows.keys():
			if y >= 0 and y < GRID_SIZE: spawn_flash_row(y); clear_row(y); el += 1
		for x in cols.keys():
			if x >= 0 and x < GRID_SIZE: spawn_flash_col(x); clear_column(x); el += 1
		trigger_shake(10.0)
	return el

func explode_at(cx, cy):
	var cw = get_shaked_grid_pos() + Vector2(cx + 0.5, cy + 0.5) * cell_size
	spawn_explosion_ring(cw, cell_size * 3.2)
	spawn_effect_burst(cw, Color(1.0, 0.55, 1.0), 18)
	spawn_effect_burst(cw, Color(0.7, 0.3, 1.0), 10)
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var x = cx + dx; var y = cy + dy
			if x < 0 or x >= GRID_SIZE or y < 0 or y >= GRID_SIZE: continue
			if grid[y][x] != null: score += 5
			grid[y][x] = null
			flash_cells.append({"x": x, "y": y, "timer": FLASH_DURATION, "max": FLASH_DURATION})
			spawn_effect_burst(get_shaked_grid_pos() + Vector2(x + 0.5, y + 0.5) * cell_size, BOMB_COLOR, 4)
	_mark_pieces_dirty()

func apply_combo(lines_cleared: int):
	if lines_cleared > 0:
		combo_streak += 1
		combo_grace_turns = COMBO_GRACE
		combo_count = combo_streak
		if combo_streak >= 5: trigger_flash(0.2 + min(0.3, combo_streak * 0.03))
		if combo_streak in [10, 15, 20, 30]: spawn_confetti()
		if combo_streak > stats.combo_max: stats.combo_max = combo_streak
		if combo_streak >= 10: stats.streak10 = max(stats.streak10, combo_streak)
		if game_mode == GameMode.CAMPAIGN:
			lvl_crystals += lines_cleared
			if combo_streak >= 3: lvl_diamonds += 1
			if combo_streak >= 5: lvl_stars += 1
			if lines_cleared >= 3: lvl_stars += 1
		var bonus = 0; var title = ""
		match lines_cleared:
			1: bonus = 100; title = "CLEAR!"
			2: bonus = 300; title = "DOUBLE!"
			3: bonus = 700; title = "TRIPLE!"
			_: bonus = 1200 + (lines_cleared - 4) * 500; title = "MASSIVE!"
		var sm = min(1.0 + (combo_streak - 1) * 0.5, 5.0)
		var total = int(bonus * sm)
		score += total
		if combo_streak > 1: spawn_combo_popup("%s  ·  COMBO x%d  +%d" % [title, combo_streak, total])
		else: spawn_combo_popup("%s  +%d" % [title, total])
		trigger_shake(6.0 + lines_cleared * 3.0 + combo_streak * 2.0)
		var pitch = clamp(1.0 + (combo_streak - 1) * 0.12, 1.0, 2.0)
		play_sfx(sfx_combo if combo_streak > 1 else sfx_clear, pitch)
		vibrate_combo(combo_streak)
		check_achievements()
	else:
		if combo_streak > 0:
			combo_grace_turns -= 1
			if combo_grace_turns <= 0:
				combo_streak = 0; combo_count = 0; combo_grace_turns = 0

func spawn_combo_popup(text):
	combo_popups.append({"text": text,
		"pos": get_shaked_grid_pos() + Vector2(GRID_SIZE * cell_size / 2.0, GRID_SIZE * cell_size / 2.0),
		"timer": COMBO_POPUP_DURATION, "max": COMBO_POPUP_DURATION})

func is_row_full(y):
	for x in range(GRID_SIZE):
		if grid[y][x] == null: return false
	return true

func is_column_full(x):
	for y in range(GRID_SIZE):
		if grid[y][x] == null: return false
	return true

func clear_row(y):
	for x in range(GRID_SIZE):
		if grid[y][x] != null:
			spawn_effect_burst(get_shaked_grid_pos() + Vector2(x + 0.5, y + 0.5) * cell_size, grid[y][x], 6)
		grid[y][x] = null
	var mid = get_shaked_grid_pos() + Vector2(GRID_SIZE * cell_size / 2.0, (y + 0.5) * cell_size)
	if not reduce_effects: spawn_explosion_ring(mid, GRID_SIZE * cell_size * 0.6)

func clear_column(x):
	for y in range(GRID_SIZE):
		if grid[y][x] != null:
			spawn_effect_burst(get_shaked_grid_pos() + Vector2(x + 0.5, y + 0.5) * cell_size, grid[y][x], 6)
		grid[y][x] = null
	var mid = get_shaked_grid_pos() + Vector2((x + 0.5) * cell_size, GRID_SIZE * cell_size / 2.0)
	if not reduce_effects: spawn_explosion_ring(mid, GRID_SIZE * cell_size * 0.6)

func spawn_flash_row(y):
	for x in range(GRID_SIZE):
		flash_cells.append({"x": x, "y": y, "timer": FLASH_DURATION, "max": FLASH_DURATION})

func spawn_flash_col(x):
	for y in range(GRID_SIZE):
		flash_cells.append({"x": x, "y": y, "timer": FLASH_DURATION, "max": FLASH_DURATION})

# ============================================================================
# MODE STARTS
# ============================================================================

func _reset_game_state():
	delete_game_state(); reset_grid()
	score = 0; displayed_score = 0.0
	combo_count = 0; combo_streak = 0; combo_grace_turns = 0
	used_revive_this_game = false; dragging_piece = -1
	pop_cells.clear(); flash_cells.clear(); combo_popups.clear()
	visual_effects.clear(); explosion_rings.clear()
	drag_trail.clear(); confetti.clear()
	score_popups.clear(); row_glow_cells.clear()
	hint_result = {}; hint_visible = false; hint_timer = 0.0
	_active_touch_index = -1; _touch_started_drag = false
	_last_piece_shapes.clear(); _last_piece_colors.clear()
	_pieces_since_bomb = 0; _pieces_since_line = 0
	cleared_lines_total = 0
	shift_lines_required = SHIFT_LINES_STEP
	shift_in_progress = false
	shift_warning_count = 0
	shift_warning_timer = 0.0
	_shift_pending_gameover = false
	for i in range(_piece_spawn_delay.size()): _piece_spawn_delay[i] = 0.0
	screen_shake = 0.0; _shake_offset = Vector2.ZERO
	flash_alpha = 0.0; _go_scatter_timer = 0.0
	field_density = 0.0; _density_pulse = 0.0
	revive_timer = 0.0; revive_active = false; revive_shown = false
	revive_delay_timer = 0.0; revive_appear = 0.0; revive_dim = 0.0
	revive_last_tick_sec = -1
	_last_ui_action_time = 0.0

func start_classic_game():
	_reset_game_state()
	game_mode = GameMode.CLASSIC
	generate_new_pieces(); _mark_pieces_dirty()
	state = State.PLAYING
	if daily_bonus_available:
		var bonus = DAILY_BONUS_SCORE * min(stats.daily_streak, 7)
		score = bonus; displayed_score = float(score)
		consume_daily(); spawn_combo_popup("DAILY x" + str(stats.daily_streak) + " +" + str(bonus))
	else: consume_daily()
	queue_redraw()

func start_time_game():
	_reset_game_state()
	game_mode = GameMode.TIME
	time_left = TIME_DURATION
	generate_new_pieces(); _mark_pieces_dirty()
	if not FileAccess.file_exists(TIME_TUTORIAL_SAVE):
		tutorial_for_mode = GameMode.TIME; tutorial_step = 0; state = State.TUTORIAL
	else: state = State.PLAYING
	queue_redraw()

func end_time_game():
	delete_game_state()
	if score > time_high:
		time_high = score; save_time_high(); spawn_confetti()
	stats.best_time = max(stats.best_time, score)
	if not used_revive_this_game: show_revive_screen()
	else:
		state = State.GAME_OVER
		_go_scatter_timer = 0.6
		play_sfx(sfx_gameover); vibrate(200)
		stats.games_played += 1; games_played_session += 1
		check_achievements(); save_progress()
		if games_played_session % INTERSTITIAL_EVERY_N_GAMES == 0: show_interstitial_ad()
	queue_redraw()

func start_campaign_level(level: int):
	_reset_game_state()
	game_mode = GameMode.CAMPAIGN
	campaign_level = level
	var goals = _get_level_goals(level)
	goal_crystals = goals["crystals"]; goal_diamonds = goals["diamonds"]; goal_stars = goals["stars"]
	lvl_crystals = 0; lvl_diamonds = 0; lvl_stars = 0
	campaign_moves_total = campaign_moves(level); campaign_moves_left = campaign_moves_total
	campaign_won = false; level_stars_earned = 0
	var pattern = _campaign_pattern(level)
	for pos in pattern: grid[pos.y][pos.x] = COLOR_PALETTE[randi() % COLOR_PALETTE.size()]
	generate_new_pieces(); _mark_pieces_dirty()
	state = State.PLAYING
	queue_redraw()

func continue_game():
	if load_game_state():
		dragging_piece = -1
		pop_cells.clear(); flash_cells.clear(); combo_popups.clear()
		visual_effects.clear(); explosion_rings.clear()
		screen_shake = 0.0; _shake_offset = Vector2.ZERO
		displayed_score = score; state = State.PLAYING
		_mark_pieces_dirty(); _recalc_density()
	else: start_classic_game()
	queue_redraw()

func campaign_moves(level: int) -> int: return max(5, 25 - int(level / 30.0))

func _get_level_goals(level: int) -> Dictionary:
	var crystals = 3 + int(level / 5.0); var diamonds = 0; var stars = 0
	if level % 3 == 0 and level >= 3: diamonds = 1 + int(level / 15.0)
	if level % 7 == 0 and level >= 7: stars = 1 + int(level / 30.0)
	return {"crystals": crystals, "diamonds": diamonds, "stars": stars}

func _campaign_pattern(level: int) -> Array:
	var cells = []
	if level <= 2: return cells
	var pt = 0
	if level <= 5: pt = 1
	elif level <= 8: pt = 2
	elif level <= 12: pt = 3
	elif level <= 16: pt = 4
	elif level <= 20: pt = 5
	elif level <= 30: pt = 6
	else: pt = 7
	match pt:
		1:
			for y in range(3):
				for x in range(3): cells.append(Vector2i(x, y))
		2:
			for i in range(2, 6):
				cells.append(Vector2i(i, 4)); cells.append(Vector2i(4, i))
		3:
			for i in range(GRID_SIZE):
				cells.append(Vector2i(i, i)); cells.append(Vector2i(i, GRID_SIZE - 1 - i))
		4:
			for i in range(GRID_SIZE):
				if not Vector2i(i, 0) in cells: cells.append(Vector2i(i, 0))
				if not Vector2i(i, GRID_SIZE - 1) in cells: cells.append(Vector2i(i, GRID_SIZE - 1))
				if not Vector2i(0, i) in cells: cells.append(Vector2i(0, i))
				if not Vector2i(GRID_SIZE - 1, i) in cells: cells.append(Vector2i(GRID_SIZE - 1, i))
		5:
			for y in range(GRID_SIZE):
				for x in range(GRID_SIZE):
					if (x + y) % 2 == 0: cells.append(Vector2i(x, y))
		6:
			var count = 15 + (level - 21); var attempts = 0
			while cells.size() < count and attempts < 100:
				attempts += 1
				var pos = Vector2i(randi() % GRID_SIZE, randi() % GRID_SIZE)
				if not pos in cells: cells.append(pos)
		7:
			var count = min(35, 25 + int((level - 30) / 10)); var attempts = 0
			while cells.size() < count and attempts < 200:
				attempts += 1
				var pos = Vector2i(randi() % GRID_SIZE, randi() % GRID_SIZE)
				if not pos in cells: cells.append(pos)
	return cells

# ============================================================================
# SAVES
# ============================================================================

func load_high_score():
	if FileAccess.file_exists(SAVE_PATH):
		var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f == null: return
		if f.get_length() >= 4: high_score = f.get_32()
		f.close()

func save_high_score():
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null: return
	f.store_32(high_score); f.close()

func load_time_high():
	if FileAccess.file_exists(TIME_SAVE_PATH):
		var f = FileAccess.open(TIME_SAVE_PATH, FileAccess.READ)
		if f == null: return
		if f.get_length() >= 4: time_high = f.get_32()
		f.close()

func save_time_high():
	var f = FileAccess.open(TIME_SAVE_PATH, FileAccess.WRITE)
	if f == null: return
	f.store_32(time_high); f.close()

func load_settings():
	if not FileAccess.file_exists(SETTINGS_SAVE_PATH): return
	var f = FileAccess.open(SETTINGS_SAVE_PATH, FileAccess.READ)
	if f == null: return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		sound_enabled = parsed.get("sound", true)
		music_enabled = parsed.get("music", true)
		vibration_enabled = parsed.get("vibration", true)
		weather_mode = int(parsed.get("weather", 1))
		current_lang = parsed.get("lang", "ru")
		if not current_lang in LANG_ORDER: current_lang = "ru"
		reduce_effects = bool(parsed.get("reduce_effects", false))

func save_settings():
	var f = FileAccess.open(SETTINGS_SAVE_PATH, FileAccess.WRITE)
	if f == null: return
	f.store_string(JSON.stringify({"sound": sound_enabled, "music": music_enabled,
		"vibration": vibration_enabled, "weather": weather_mode, "lang": current_lang,
		"reduce_effects": reduce_effects}))
	f.close()

func load_skin():
	if not FileAccess.file_exists(SKIN_SAVE_PATH): return
	var f = FileAccess.open(SKIN_SAVE_PATH, FileAccess.READ)
	if f == null: return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary: current_skin_id = str(parsed.get("current", "neon"))
	var valid = false
	for s in SKINS:
		if s.id == current_skin_id: valid = true; break
	if not valid: current_skin_id = "neon"

func save_skin():
	var f = FileAccess.open(SKIN_SAVE_PATH, FileAccess.WRITE)
	if f == null: return
	f.store_string(JSON.stringify({"current": current_skin_id})); f.close()

func load_progress():
	if not FileAccess.file_exists(PROGRESS_SAVE_PATH): return
	var f = FileAccess.open(PROGRESS_SAVE_PATH, FileAccess.READ)
	if f == null: return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		campaign_max_unlocked = int(parsed.get("campaign_max", 1))
		campaign_level = max(1, campaign_max_unlocked)
		ach_unlocked = parsed.get("ach", {})
		stats.total_lines = int(parsed.get("total_lines", 0))
		stats.total_bombs = int(parsed.get("total_bombs", 0))
		stats.games_played = int(parsed.get("games_played", 0))
		stats.best_score = int(parsed.get("best_score", 0))
		stats.best_time = int(parsed.get("best_time", 0))
		stats.combo_max = int(parsed.get("combo_max", 0))
		stats.triple_clear = int(parsed.get("triple_clear", 0))
		stats.five_clear = int(parsed.get("five_clear", 0))
		stats.perfect_clear = int(parsed.get("perfect_clear", 0))
		stats.comeback = int(parsed.get("comeback", 0))
		stats.streak10 = int(parsed.get("streak10", 0))
		stats.play_first = int(parsed.get("play_first", 0))
		stats.night_owl = int(parsed.get("night_owl", 0))
		stats.early_bird = int(parsed.get("early_bird", 0))
		stats.daily_streak = int(parsed.get("daily_streak", 0))
		var su = parsed.get("skins_used", {})
		if su is Dictionary: stats.skins_used = su
		var ls = parsed.get("level_stars", {})
		if ls is Dictionary: level_stars_saved = ls

func save_progress():
	var f = FileAccess.open(PROGRESS_SAVE_PATH, FileAccess.WRITE)
	if f == null: return
	f.store_string(JSON.stringify({
		"campaign_max": campaign_max_unlocked, "ach": ach_unlocked,
		"total_lines": stats.total_lines, "total_bombs": stats.total_bombs,
		"games_played": stats.games_played, "best_score": stats.best_score,
		"best_time": stats.best_time, "combo_max": stats.combo_max,
		"triple_clear": stats.triple_clear, "five_clear": stats.five_clear,
		"perfect_clear": stats.perfect_clear, "comeback": stats.comeback,
		"streak10": stats.streak10, "play_first": stats.play_first,
		"night_owl": stats.night_owl, "early_bird": stats.early_bird,
		"daily_streak": stats.daily_streak, "skins_used": stats.skins_used,
		"level_stars": level_stars_saved}))
	f.close()

var daily_bonus_available = false

func load_daily():
	var tdict = Time.get_datetime_dict_from_system()
	var today = "%04d-%02d-%02d" % [int(tdict.year), int(tdict.month), int(tdict.day)]
	var last = ""
	if FileAccess.file_exists(DAILY_SAVE_PATH):
		var f = FileAccess.open(DAILY_SAVE_PATH, FileAccess.READ)
		if f != null: last = f.get_as_text().strip_edges(); f.close()
	if last != today:
		daily_bonus_available = true
		var yday = _subtract_one_day(tdict)
		var yesterday_str = "%04d-%02d-%02d" % [int(yday.year), int(yday.month), int(yday.day)]
		if last == yesterday_str: stats.daily_streak += 1
		else: stats.daily_streak = 1
		var f2 = FileAccess.open(DAILY_SAVE_PATH, FileAccess.WRITE)
		if f2 != null: f2.store_string(today); f2.close()
		save_progress()

func _subtract_one_day(d: Dictionary) -> Dictionary:
	var day = int(d.day) - 1; var month = int(d.month); var year = int(d.year)
	if day < 1:
		month -= 1
		if month < 1: month = 12; year -= 1
		day = _days_in_month(year, month)
	return {"year": year, "month": month, "day": day}

func _days_in_month(y: int, m: int) -> int:
	match m:
		1, 3, 5, 7, 8, 10, 12: return 31
		4, 6, 9, 11: return 30
		2: return 29 if ((y % 4 == 0 and y % 100 != 0) or y % 400 == 0) else 28
	return 30

func consume_daily(): daily_bonus_available = false

func serialize_color(c):
	if c == null: return null
	return [c.r, c.g, c.b, c.a]

func deserialize_color(arr):
	if arr == null: return null
	if not (arr is Array) or arr.size() < 4: return null
	return Color(float(arr[0]), float(arr[1]), float(arr[2]), float(arr[3]))

func save_game_state():
	if game_mode == GameMode.CAMPAIGN: return
	var gd = []
	for y in range(GRID_SIZE):
		var row = []
		for x in range(GRID_SIZE): row.append(serialize_color(grid[y][x]))
		gd.append(row)
	var pd = []
	for p in pieces:
		var bd = []
		for b in p["blocks"]: bd.append([b.x, b.y])
		pd.append({"blocks": bd, "color": serialize_color(p["color"]), "type": p["type"]})
	var data = {"grid": gd, "pieces": pd, "score": score,
		"combo_count": combo_count, "combo_streak": combo_streak,
		"combo_grace": combo_grace_turns, "mode": game_mode,
		"cleared_lines_total": cleared_lines_total,
		"shift_lines_required": shift_lines_required}
	var f = FileAccess.open(GAME_SAVE_PATH, FileAccess.WRITE)
	if f == null: return
	f.store_string(JSON.stringify(data)); f.close()
	has_saved_game = true

func load_game_state():
	if not FileAccess.file_exists(GAME_SAVE_PATH): return false
	var f = FileAccess.open(GAME_SAVE_PATH, FileAccess.READ)
	if f == null: return false
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary): return false
	if not parsed.has_all(["grid", "pieces", "score"]): return false
	var gd = parsed["grid"]
	if not (gd is Array) or gd.size() != GRID_SIZE: return false
	for y in range(GRID_SIZE):
		if not (gd[y] is Array) or gd[y].size() != GRID_SIZE: return false
	var pd = parsed["pieces"]
	if not (pd is Array): return false
	var new_pieces: Array = []
	for p in pd:
		if not (p is Dictionary): return false
		if not p.has("blocks") or not p.has("color"): return false
		if not (p["blocks"] is Array): return false
		var blocks: Array = []
		for b in p["blocks"]:
			if not (b is Array) or b.size() < 2: return false
			blocks.append(Vector2i(int(b[0]), int(b[1])))
		var col = p["color"]
		var color: Color
		if col == null: color = Color.WHITE
		elif col is Array and col.size() >= 4:
			color = Color(float(col[0]), float(col[1]), float(col[2]), float(col[3]))
		else: return false
		var ptype: String = "normal"
		if p.has("type"): ptype = str(p["type"])
		new_pieces.append({"blocks": blocks, "color": color, "type": ptype})
	var sc = parsed["score"]
	if not (sc is float or sc is int): return false
	reset_grid()
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			grid[y][x] = deserialize_color(gd[y][x])
	pieces = new_pieces
	score = int(sc)
	combo_count = int(parsed.get("combo_count", 0))
	combo_streak = int(parsed.get("combo_streak", combo_count))
	combo_grace_turns = int(parsed.get("combo_grace", 0))
	game_mode = int(parsed.get("mode", GameMode.CLASSIC))
	cleared_lines_total = int(parsed.get("cleared_lines_total", 0))
	shift_lines_required = int(parsed.get("shift_lines_required", SHIFT_LINES_STEP))
	if game_mode == GameMode.TIME: time_left = TIME_DURATION
	_mark_pieces_dirty(); _recalc_density()
	return true

func delete_game_state():
	if FileAccess.file_exists(GAME_SAVE_PATH): DirAccess.remove_absolute(GAME_SAVE_PATH)
	has_saved_game = false
