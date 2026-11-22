package com.courier.messenger.ui.components

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.courier.messenger.ui.theme.LocalIos
import kotlin.math.PI
import kotlin.math.sin

/** Shared clock for the drifting blobs so independent panels stay in sync. */
@Composable
internal fun backdropPhase(): Float {
    val transition = rememberInfiniteTransition(label = "backdrop")
    val phase by transition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 14_000, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse,
        ),
        label = "phase",
    )
    return phase
}

/** Three radial light sources: the colour that the glass refracts. */
internal fun DrawScope.liquidBlobs(accent: Color, dark: Boolean, phase: Float, saturation: Float = 1f) {
    val w = size.width
    val h = size.height
    val drift = sin(phase * PI.toFloat())
    drawCircle(
        brush = Brush.radialGradient(
            listOf(accent.copy(alpha = (if (dark) 0.50f else 0.34f) * saturation), Color.Transparent),
        ),
        radius = w * 0.62f,
        center = Offset(w * (0.16f + 0.10f * drift), h * (0.18f + 0.04f * drift)),
    )
    drawCircle(
        brush = Brush.radialGradient(
            listOf(Color(0xFF8E7CFF).copy(alpha = (if (dark) 0.42f else 0.26f) * saturation), Color.Transparent),
        ),
        radius = w * 0.55f,
        center = Offset(w * (0.84f - 0.12f * drift), h * (0.30f + 0.06f * drift)),
    )
    drawCircle(
        brush = Brush.radialGradient(
            listOf(Color(0xFF4FD1C5).copy(alpha = (if (dark) 0.30f else 0.20f) * saturation), Color.Transparent),
        ),
        radius = w * 0.60f,
        center = Offset(w * (0.30f + 0.10f * drift), h * (0.86f - 0.05f * drift)),
    )
}

/**
 * iOS-like glass panel: blurred colour field underneath, AGSL refraction and a
 * specular rim on top of it.
 */
@Composable
fun GlassPanel(
    modifier: Modifier = Modifier,
    shape: Shape = RoundedCornerShape(26.dp),
    tint: Color = Color.White,
    strength: Float = 0.26f,
    cornerRadius: Dp = 26.dp,
    content: @Composable BoxScope.() -> Unit,
) {
    val ios = LocalIos.current
    val phase = backdropPhase()
    val radiusPx = with(androidx.compose.ui.platform.LocalDensity.current) { cornerRadius.toPx() }

    Box(
        modifier = modifier
            .clip(shape)
            .drawBehind {
                paintLiquidGlass(tint, strength, radiusPx, lightX = 0.85f)
                paintSpecular(radiusPx, ios.isDark)
            },
    ) {
        Canvas(Modifier.matchParentSize().blur(38.dp)) {
            liquidBlobs(ios.accent, ios.isDark, phase, saturation = 0.55f)
        }
        content()
    }
}

/** Animated colour blobs behind the content — the "liquid" in liquid glass. */
@Composable
fun LiquidBackdrop(modifier: Modifier = Modifier, content: @Composable BoxScope.() -> Unit) {
    val ios = LocalIos.current
    val phase = backdropPhase()
    Box(modifier) {
        Canvas(Modifier.fillMaxSize().blur(72.dp)) {
            drawRect(ios.background)
            liquidBlobs(ios.accent, ios.isDark, phase)
        }
        content()
    }
}

/** A single glass circle for nav-bar actions, as used on the Chats screen. */
@Composable
fun GlassCircleButton(
    modifier: Modifier = Modifier,
    size: Dp = 40.dp,
    onClick: () -> Unit = {},
    content: @Composable BoxScope.() -> Unit,
) {
    val ios = LocalIos.current
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    val scale by animateFloatAsState(
        targetValue = if (pressed) 0.92f else 1f,
        animationSpec = spring(dampingRatio = 0.5f, stiffness = 900f),
        label = "circleScale",
    )
    GlassPanel(
        modifier = modifier
            .size(size)
            .scale(scale)
            .clickable(interactionSource = interaction, indication = null, onClick = onClick),
        shape = RoundedCornerShape(size / 2),
        cornerRadius = size / 2,
        strength = if (ios.isDark) 0.28f else 0.22f,
    ) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center, content = content)
    }
}
