class_name ChallengePanel
extends OverlayPanel
## Daily challenge intro: today's modifier, target and reward, best today, PLAY.

const DESCRIPTIONS := {
	"FAST CURRENT": "THE CURRENT IS 25% FASTER",
	"NARROW GAPS": "EVERY GAP IS SMALLER",
	"JELLY SWARM": "JELLYFISH EVERYWHERE FROM THE START",
	"COIN RUSH": "A COIN IN EVERY GAP",
	"MOVING CORAL": "HALF OF THE CORAL MOVES",
	"SHARK ALLEY": "SHARKS FROM SCORE 5",
}


func _init() -> void:
	title = "DAILY CHALLENGE"
	panel_size = Vector2(330, 380)


func build() -> void:
	var cx := panel_rect.get_center().x
	var mod := Daily.challenge_modifier()
	UiUtil.label(self, tr(mod), 18, Color.WHITE, cx, content_top + 14, true)
	UiUtil.label(self, tr(DESCRIPTIONS[mod]), 11, Constants.UI_MUTED_TEXT, cx, content_top + 38)
	UiUtil.label(self, tr("SAME CORAL FOR EVERYONE TODAY"), 10, Constants.UI_MUTED_TEXT, cx, content_top + 56)
	UiUtil.label(self, tr("TARGET: SCORE %d") % Constants.CHALLENGE_TARGET, 15, Constants.UI_GOLD_TEXT, cx, content_top + 96, true)
	if Daily.challenge_claimed():
		UiUtil.label(self, tr("REWARD CLAIMED TODAY"), 12, Constants.UI_GREEN, cx, content_top + 122)
	else:
		UiUtil.label(self, tr("REWARD: %d COINS") % Constants.CHALLENGE_REWARD, 12, Constants.UI_GREEN, cx, content_top + 122)
	UiUtil.label(self, tr("BEST TODAY: %d") % Daily.challenge_best(), 12, Color.WHITE, cx, content_top + 146)

	var play := PixelButton.create(tr("PLAY CHALLENGE"), Constants.UI_ORANGE, Color.BLACK, Vector2(260, 56), 16)
	play.place_bottom_center(cx, panel_rect.end.y - 52)
	play.pressed.connect(func(): SceneRouter.go_to("game", SceneRouter.Transition.FADE, 0.3, {"challenge": true}))
	add_child(play)
