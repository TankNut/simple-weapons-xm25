// Created by Crowbar 0.63

$modelname "simple_weapons/weapons/w_xm25.mdl"

$bodygroup "studio"
{
	studio "w_xm25.smd"
}

$surfaceprop "weapon"
$contents "solid"

$cdmaterials "models\simple_weapons\weapons\xm25\"

$attachment "muzzle_flash" "tag_weapon" 3.59 0 0.31 rotate 0 0 0
$attachment "shelleject" "tag_brass" 0 0 0 rotate 0 0 0
$attachment "3" "tag_weapon" 3.59 0 0.31 rotate 0 0 0

$hboxset "default"

$sequence "idle" {
	"w_xm25_anims\idle.smd"
	fadein 0.2
	fadeout 0.2
	fps 30
}

$collisionmodel "w_xm25_physics.smd"
{
	$mass 1
	$inertia 1
	$damping 0
	$rotdamping 0
	$rootbone " "
	$concave
}
