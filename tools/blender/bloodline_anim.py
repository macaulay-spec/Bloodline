"""Animation library for BLOODLINE fighters.

Every clip is authored against the shared bone hierarchy, so a clip authored
for one fighter plays on all of them. Clips are written to the armature's
active action; the caller exports them to glTF.

Frame rate: 60 ticks per second (see project settings physics_ticks_per_second).
"""

from bloodline_rig import deg, key, new_action, rest_pose

FPS = 60


def _stance(arm, frame, forward=0.0, guard=0.0, crouch=0.0):
    """A reusable fighting stance.

    forward  0..1  how far the lead shoulder rotates in
    guard    0..1  how tucked the arms are
    crouch   0..1  how low the hips sit
    """
    key(arm, "Hips", frame, rot=(deg(crouch * 12), 0.0, 0.0),
        loc=(0.0, 0.0, -crouch * 0.18))
    key(arm, "Spine", frame, rot=(deg(crouch * 8), 0.0, deg(-forward * 6)))
    key(arm, "Chest", frame, rot=(deg(crouch * 6), 0.0, deg(-forward * 10)))
    key(arm, "Head", frame, rot=(0.0, 0.0, deg(forward * 4)))
    # Lead arm (left) is forward and slightly tucked.
    key(arm, "UpperArm.L", frame, rot=(deg(-18 - guard * 22), deg(-14 - forward * 26),
                                      deg(38 + forward * 20)))
    key(arm, "LowerArm.L", frame, rot=(0.0, deg(-72 - guard * 24), 0.0))
    key(arm, "Hand.L", frame, rot=(0.0, 0.0, deg(-10)))
    # Rear arm (right) is tucked near the chin.
    key(arm, "UpperArm.R", frame, rot=(deg(-10 - guard * 18), deg(10), deg(-30 - forward * 8)))
    key(arm, "LowerArm.R", frame, rot=(0.0, deg(-96 - guard * 12), 0.0))
    key(arm, "Hand.R", frame, rot=(0.0, 0.0, deg(12)))
    # Legs: staggered, weight on the rear leg.
    key(arm, "UpperLeg.L", frame, rot=(deg(-crouch * 26), 0.0, 0.0))
    key(arm, "LowerLeg.L", frame, rot=(deg(crouch * 18 + 6), 0.0, 0.0))
    key(arm, "Foot.L", frame, rot=(0.0, 0.0, 0.0))
    key(arm, "UpperLeg.R", frame, rot=(deg(crouch * 16), 0.0, 0.0))
    key(arm, "LowerLeg.R", frame, rot=(deg(crouch * 22 + 12), 0.0, 0.0))
    key(arm, "Foot.R", frame, rot=(0.0, 0.0, 0.0))
    key(arm, "Root", frame, rot=(0.0, 0.0, 0.0))


def clip_idle(arm):
    """A 2-second breathing loop. The game's default rest pose."""
    new_action(arm, "idle")
    rest_pose(arm)
    _stance(arm, 1, forward=0.15, guard=0.35, crouch=0.25)
    _stance(arm, 30, forward=0.18, guard=0.35, crouch=0.20)
    _stance(arm, 60, forward=0.15, guard=0.35, crouch=0.25)
    _stance(arm, 90, forward=0.12, guard=0.35, crouch=0.30)
    _stance(arm, 120, forward=0.15, guard=0.35, crouch=0.25)
    return "idle"


def clip_walk_forward(arm):
    """A 1-second forward walk cycle."""
    new_action(arm, "walk_forward")
    rest_pose(arm)
    for f, (swing, lift) in enumerate(
            [(0.0, 0.0), (15.0, 26.0), (30.0, 0.0), (45.0, 0.0), (60.0, 0.0)]):
        key(arm, "Hips", 1 + f, rot=(deg(2), 0.0, deg(3)),
            loc=(0.0, 0.0, -abs(lift) * 0.004))
        key(arm, "Spine", 1 + f, rot=(0.0, 0.0, deg(-4)))
        key(arm, "Chest", 1 + f, rot=(0.0, 0.0, deg(-6)))
        key(arm, "UpperLeg.L", 1 + f, rot=(deg(swing * 0.6), 0.0, 0.0))
        key(arm, "LowerLeg.L", 1 + f, rot=(deg(max(0.0, -swing) + lift * 0.5), 0.0, 0.0))
        key(arm, "UpperLeg.R", 1 + f, rot=(deg(-swing * 0.6), 0.0, 0.0))
        key(arm, "LowerLeg.R", 1 + f, rot=(deg(max(0.0, swing) + lift * 0.5), 0.0, 0.0))
        key(arm, "Foot.L", 1 + f, rot=(deg(-lift * 0.15), 0.0, 0.0))
        key(arm, "Foot.R", 1 + f, rot=(deg(-lift * 0.15), 0.0, 0.0))
        key(arm, "UpperArm.L", 1 + f, rot=(deg(-swing * 0.55), deg(-12), deg(26)))
        key(arm, "LowerArm.L", 1 + f, rot=(0.0, deg(-64), 0.0))
        key(arm, "UpperArm.R", 1 + f, rot=(deg(swing * 0.55), deg(10), deg(-24)))
        key(arm, "LowerArm.R", 1 + f, rot=(0.0, deg(-70), 0.0))
    return "walk_forward"


def clip_walk_back(arm):
    """A 1-second backward shuffle, guard maintained."""
    new_action(arm, "walk_back")
    rest_pose(arm)
    for f, (swing, lift) in enumerate(
            [(0.0, 0.0), (15.0, 14.0), (30.0, 0.0), (45.0, 0.0), (60.0, 0.0)]):
        key(arm, "Hips", 1 + f, rot=(deg(3), 0.0, deg(-2)))
        key(arm, "Spine", 1 + f, rot=(0.0, 0.0, deg(3)))
        key(arm, "Chest", 1 + f, rot=(0.0, 0.0, deg(4)))
        key(arm, "UpperLeg.L", 1 + f, rot=(deg(-swing * 0.5), 0.0, 0.0))
        key(arm, "LowerLeg.L", 1 + f, rot=(deg(max(0.0, swing) + lift * 0.4), 0.0, 0.0))
        key(arm, "UpperLeg.R", 1 + f, rot=(deg(swing * 0.5), 0.0, 0.0))
        key(arm, "LowerLeg.R", 1 + f, rot=(deg(max(0.0, -swing) + lift * 0.4), 0.0, 0.0))
        key(arm, "UpperArm.L", 1 + f, rot=(deg(-20), deg(-16), deg(40)))
        key(arm, "LowerArm.L", 1 + f, rot=(0.0, deg(-84), 0.0))
        key(arm, "UpperArm.R", 1 + f, rot=(deg(-14), deg(12), deg(-32)))
        key(arm, "LowerArm.R", 1 + f, rot=(0.0, deg(-98), 0.0))
    return "walk_back"


def clip_guard(arm):
    """Guard hold. Both arms up, weight back."""
    new_action(arm, "guard")
    rest_pose(arm)
    _stance(arm, 1, forward=0.0, guard=1.0, crouch=0.42)
    _stance(arm, 30, forward=0.0, guard=1.0, crouch=0.38)
    return "guard"


def clip_light_attack(arm):
    """Fast jab. 8f startup, 3f active, 12f recovery (see combat data)."""
    new_action(arm, "light_attack")
    rest_pose(arm)
    _stance(arm, 1, forward=0.2, guard=0.3, crouch=0.25)
    _stance(arm, 5, forward=0.05, guard=0.5, crouch=0.3)
    # wind-up
    key(arm, "Hips", 7, rot=(deg(2), deg(4), deg(-4)))
    key(arm, "Chest", 7, rot=(0.0, deg(-6), deg(-14)))
    key(arm, "UpperArm.L", 7, rot=(deg(-30), deg(-34), deg(18)))
    key(arm, "LowerArm.L", 7, rot=(0.0, deg(-96), 0.0))
    # strike
    key(arm, "Hips", 10, rot=(deg(-2), deg(-8), deg(8)))
    key(arm, "Chest", 10, rot=(0.0, deg(10), deg(12)))
    key(arm, "UpperArm.L", 10, rot=(deg(-4), deg(6), deg(-6)))
    key(arm, "LowerArm.L", 10, rot=(0.0, deg(-6), 0.0))
    # hold then recover
    key(arm, "UpperArm.L", 13, rot=(deg(-4), deg(6), deg(-6)))
    key(arm, "LowerArm.L", 13, rot=(0.0, deg(-6), 0.0))
    _stance(arm, 25, forward=0.2, guard=0.3, crouch=0.25)
    return "light_attack"


def clip_heavy_attack(arm):
    """Slow, committed swing. 20f startup, 5f active, 26f recovery."""
    new_action(arm, "heavy_attack")
    rest_pose(arm)
    _stance(arm, 1, forward=0.15, guard=0.35, crouch=0.25)
    # long wind-up, weight shifts back
    key(arm, "Hips", 8, rot=(deg(-4), deg(8), deg(-12)))
    key(arm, "Spine", 8, rot=(deg(-3), deg(6), deg(-16)))
    key(arm, "Chest", 8, rot=(0.0, deg(10), deg(-30)))
    key(arm, "Head", 8, rot=(0.0, deg(6), deg(-10)))
    key(arm, "UpperArm.R", 8, rot=(deg(-40), deg(30), deg(-58)))
    key(arm, "LowerArm.R", 8, rot=(0.0, deg(-120), 0.0))
    key(arm, "UpperArm.L", 8, rot=(deg(-16), deg(-30), deg(40)))
    key(arm, "LowerArm.L", 8, rot=(0.0, deg(-110), 0.0))
    key(arm, "UpperLeg.R", 8, rot=(deg(-10), 0.0, 0.0))
    # step in and swing
    key(arm, "Hips", 22, rot=(deg(4), deg(-12), deg(16)))
    key(arm, "Spine", 22, rot=(deg(3), deg(-8), deg(14)))
    key(arm, "Chest", 22, rot=(0.0, deg(-14), deg(26)))
    key(arm, "UpperArm.R", 22, rot=(deg(-6), deg(-16), deg(4)))
    key(arm, "LowerArm.R", 22, rot=(0.0, deg(-16), 0.0))
    key(arm, "UpperArm.L", 22, rot=(deg(-12), deg(-8), deg(26)))
    key(arm, "LowerArm.L", 22, rot=(0.0, deg(-78), 0.0))
    key(arm, "UpperLeg.L", 22, rot=(deg(-22), 0.0, 0.0))
    key(arm, "LowerLeg.L", 22, rot=(deg(16), 0.0, 0.0))
    # hold
    key(arm, "UpperArm.R", 27, rot=(deg(-6), deg(-16), deg(4)))
    key(arm, "LowerArm.R", 27, rot=(0.0, deg(-16), 0.0))
    # long recovery back to stance
    key(arm, "Hips", 40, rot=(deg(2), deg(-2), deg(4)))
    key(arm, "Chest", 40, rot=(0.0, deg(-2), deg(4)))
    key(arm, "UpperArm.R", 40, rot=(deg(-14), deg(10), deg(-32)))
    key(arm, "LowerArm.R", 40, rot=(0.0, deg(-92), 0.0))
    _stance(arm, 52, forward=0.15, guard=0.35, crouch=0.25)
    return "heavy_attack"


def clip_dodge(arm):
    """Quick evasive step-back. i-frames live in the middle of the clip."""
    new_action(arm, "dodge")
    rest_pose(arm)
    _stance(arm, 1, forward=0.15, guard=0.35, crouch=0.25)
    key(arm, "Hips", 6, rot=(deg(6), deg(-6), deg(8)),
        loc=(0.0, 0.0, -0.06))
    key(arm, "Spine", 6, rot=(deg(4), 0.0, deg(6)))
    key(arm, "Chest", 6, rot=(0.0, 0.0, deg(10)))
    key(arm, "UpperArm.L", 6, rot=(deg(-24), deg(-24), deg(46)))
    key(arm, "LowerArm.L", 6, rot=(0.0, deg(-92), 0.0))
    key(arm, "UpperArm.R", 6, rot=(deg(-18), deg(18), deg(-40)))
    key(arm, "LowerArm.R", 6, rot=(0.0, deg(-104), 0.0))
    key(arm, "UpperLeg.L", 6, rot=(deg(-30), 0.0, 0.0))
    key(arm, "LowerLeg.L", 6, rot=(deg(34), 0.0, 0.0))
    key(arm, "UpperLeg.R", 6, rot=(deg(14), 0.0, 0.0))
    key(arm, "LowerLeg.R", 6, rot=(deg(24), 0.0, 0.0))
    # recover
    key(arm, "Hips", 20, rot=(0.0, 0.0, 0.0), loc=(0.0, 0.0, 0.0))
    _stance(arm, 30, forward=0.15, guard=0.35, crouch=0.25)
    return "dodge"


def clip_ability(arm):
    """Signature ability: Veil energy flares, body squares up."""
    new_action(arm, "ability")
    rest_pose(arm)
    _stance(arm, 1, forward=0.15, guard=0.35, crouch=0.25)
    key(arm, "Hips", 12, rot=(deg(-6), 0.0, 0.0), loc=(0.0, 0.0, -0.05))
    key(arm, "Spine", 12, rot=(deg(-8), 0.0, 0.0))
    key(arm, "Chest", 12, rot=(deg(-6), 0.0, 0.0))
    key(arm, "Neck", 12, rot=(deg(8), 0.0, 0.0))
    key(arm, "Head", 12, rot=(deg(10), 0.0, 0.0))
    # arms thrown wide, palms open
    for side, sgn in (("L", 1.0), ("R", -1.0)):
        key(arm, "UpperArm." + side, 12, rot=(deg(-30), deg(sgn * 40), deg(sgn * 62)))
        key(arm, "LowerArm." + side, 12, rot=(0.0, deg(-30), 0.0))
        key(arm, "Hand." + side, 12, rot=(0.0, 0.0, deg(sgn * 20)))
    key(arm, "UpperLeg.L", 12, rot=(deg(-18), 0.0, 0.0))
    key(arm, "UpperLeg.R", 12, rot=(deg(10), 0.0, 0.0))
    # settle into a powered stance
    _stance(arm, 34, forward=0.4, guard=0.15, crouch=0.3)
    key(arm, "Chest", 34, rot=(deg(-4), 0.0, deg(-14)))
    _stance(arm, 70, forward=0.4, guard=0.15, crouch=0.3)
    return "ability"


def clip_hit(arm):
    """Reaction to being hit: recoil back."""
    new_action(arm, "hit")
    rest_pose(arm)
    _stance(arm, 1, forward=0.15, guard=0.35, crouch=0.25)
    key(arm, "Hips", 4, rot=(deg(10), deg(-6), deg(6)), loc=(0.0, 0.0, -0.03))
    key(arm, "Spine", 4, rot=(deg(12), deg(-4), deg(4)))
    key(arm, "Chest", 4, rot=(deg(8), deg(-6), deg(6)))
    key(arm, "Head", 4, rot=(deg(14), deg(-6), deg(-6)))
    key(arm, "UpperArm.L", 4, rot=(deg(6), deg(20), deg(44)))
    key(arm, "LowerArm.L", 4, rot=(0.0, deg(-52), 0.0))
    key(arm, "UpperArm.R", 4, rot=(deg(4), deg(-18), deg(-38)))
    key(arm, "LowerArm.R", 4, rot=(0.0, deg(-64), 0.0))
    key(arm, "UpperLeg.L", 4, rot=(deg(-10), 0.0, 0.0))
    key(arm, "UpperLeg.R", 4, rot=(deg(6), 0.0, 0.0))
    # settle
    key(arm, "Hips", 16, rot=(0.0, 0.0, 0.0), loc=(0.0, 0.0, 0.0))
    _stance(arm, 24, forward=0.15, guard=0.35, crouch=0.25)
    return "hit"


def clip_block(arm):
    """Guarded contact: small flinch, arms stay up."""
    new_action(arm, "block")
    rest_pose(arm)
    _stance(arm, 1, forward=0.0, guard=1.0, crouch=0.42)
    key(arm, "Hips", 3, rot=(deg(4), deg(-4), deg(4)), loc=(0.0, 0.0, -0.05))
    key(arm, "Chest", 3, rot=(deg(4), deg(-4), deg(4)))
    key(arm, "UpperArm.L", 3, rot=(deg(-26), deg(-20), deg(44)))
    key(arm, "LowerArm.L", 3, rot=(0.0, deg(-96), 0.0))
    key(arm, "UpperArm.R", 3, rot=(deg(-22), deg(16), deg(-40)))
    key(arm, "LowerArm.R", 3, rot=(0.0, deg(-104), 0.0))
    _stance(arm, 12, forward=0.0, guard=1.0, crouch=0.42)
    return "block"


def clip_knockdown(arm):
    """Falling to the floor."""
    new_action(arm, "knockdown")
    rest_pose(arm)
    _stance(arm, 1, forward=0.15, guard=0.35, crouch=0.25)
    key(arm, "Hips", 10, rot=(deg(24), deg(-10), deg(12)), loc=(0.0, 0.0, -0.30))
    key(arm, "Spine", 10, rot=(deg(20), deg(-6), deg(6)))
    key(arm, "Chest", 10, rot=(deg(16), deg(-8), deg(8)))
    key(arm, "Head", 10, rot=(deg(20), 0.0, 0.0))
    for side, sgn in (("L", 1.0), ("R", -1.0)):
        key(arm, "UpperArm." + side, 10, rot=(deg(30), deg(sgn * 30), deg(sgn * 60)))
        key(arm, "LowerArm." + side, 10, rot=(0.0, deg(-40), 0.0))
    key(arm, "UpperLeg.L", 10, rot=(deg(-50), 0.0, 0.0))
    key(arm, "LowerLeg.L", 10, rot=(deg(70), 0.0, 0.0))
    key(arm, "UpperLeg.R", 10, rot=(deg(-30), 0.0, 0.0))
    key(arm, "LowerLeg.R", 10, rot=(deg(40), 0.0, 0.0))
    # prone
    key(arm, "Hips", 26, rot=(deg(74), 0.0, deg(6)), loc=(0.0, -0.18, -0.72))
    key(arm, "Spine", 26, rot=(deg(10), 0.0, 0.0))
    key(arm, "Chest", 26, rot=(deg(6), 0.0, 0.0))
    key(arm, "Head", 26, rot=(deg(10), 0.0, 0.0))
    for side, sgn in (("L", 1.0), ("R", -1.0)):
        key(arm, "UpperArm." + side, 26, rot=(deg(6), deg(sgn * 40), deg(sgn * 76)))
        key(arm, "LowerArm." + side, 26, rot=(0.0, deg(-24), 0.0))
    key(arm, "UpperLeg.L", 26, rot=(deg(-14), 0.0, 0.0))
    key(arm, "LowerLeg.L", 26, rot=(deg(16), 0.0, 0.0))
    key(arm, "UpperLeg.R", 26, rot=(deg(-8), 0.0, 0.0))
    key(arm, "LowerLeg.R", 26, rot=(deg(12), 0.0, 0.0))
    return "knockdown"


def clip_victory(arm):
    """Post-match stance."""
    new_action(arm, "victory")
    rest_pose(arm)
    _stance(arm, 1, forward=0.1, guard=0.2, crouch=0.15)
    key(arm, "Hips", 14, rot=(0.0, 0.0, 0.0))
    key(arm, "Chest", 14, rot=(deg(-6), 0.0, deg(6)))
    key(arm, "Head", 14, rot=(deg(-8), 0.0, 0.0))
    key(arm, "UpperArm.L", 14, rot=(deg(-16), deg(24), deg(52)))
    key(arm, "LowerArm.L", 14, rot=(0.0, deg(-30), 0.0))
    key(arm, "UpperArm.R", 14, rot=(deg(-14), deg(-16), deg(-30)))
    key(arm, "LowerArm.R", 14, rot=(0.0, deg(-70), 0.0))
    key(arm, "UpperLeg.L", 14, rot=(deg(-6), 0.0, 0.0))
    key(arm, "UpperLeg.R", 14, rot=(deg(4), 0.0, 0.0))
    _stance(arm, 40, forward=0.1, guard=0.2, crouch=0.15)
    return "victory"


def clip_defeat(arm):
    """Stagger and slump, used at match end."""
    new_action(arm, "defeat")
    rest_pose(arm)
    _stance(arm, 1, forward=0.15, guard=0.35, crouch=0.25)
    key(arm, "Hips", 18, rot=(deg(16), 0.0, 0.0), loc=(0.0, 0.0, -0.24))
    key(arm, "Spine", 18, rot=(deg(14), 0.0, 0.0))
    key(arm, "Chest", 18, rot=(deg(12), 0.0, 0.0))
    key(arm, "Head", 18, rot=(deg(22), 0.0, 0.0))
    for side, sgn in (("L", 1.0), ("R", -1.0)):
        key(arm, "UpperArm." + side, 18, rot=(deg(18), deg(sgn * 26), deg(sgn * 54)))
        key(arm, "LowerArm." + side, 18, rot=(0.0, deg(-34), 0.0))
    key(arm, "UpperLeg.L", 18, rot=(deg(-34), 0.0, 0.0))
    key(arm, "LowerLeg.L", 18, rot=(deg(46), 0.0, 0.0))
    key(arm, "UpperLeg.R", 18, rot=(deg(-14), 0.0, 0.0))
    key(arm, "LowerLeg.R", 18, rot=(deg(24), 0.0, 0.0))
    return "defeat"


ALL_CLIPS = [
    clip_idle,
    clip_walk_forward,
    clip_walk_back,
    clip_guard,
    clip_light_attack,
    clip_heavy_attack,
    clip_dodge,
    clip_ability,
    clip_hit,
    clip_block,
    clip_knockdown,
    clip_victory,
    clip_defeat,
]
