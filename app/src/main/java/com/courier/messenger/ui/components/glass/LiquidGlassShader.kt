package com.courier.messenger.ui.components

import android.graphics.Paint
import android.graphics.RuntimeShader
import android.os.Build
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.nativeCanvas

/**
 * AGSL source for the Liquid Glass body.
 *
 * The signed distance field [d] defines the rounded silhouette. Its normal
 * produces the specular lobe on the light side, the rim band bends colour like
 * a refracting edge, and a faint chromatic offset plus grain keeps the surface
 * from looking like flat translucency. Everything is computed per fragment, so
 * no bitmap snapshot or extra render pass is needed.
 */
internal object LiquidGlassShader {

    const val SOURCE = """
        uniform float2 uSize;
        uniform float uRadius;
        uniform float uStrength;
        uniform float3 uTint;
        uniform float2 uLight;

        half4 main(float2 fragCoord) {
            float2 halfSize = uSize * 0.5;
            float2 p = fragCoord - halfSize;
            float2 q = abs(p) - (halfSize - uRadius);
            float d = length(max(q, float2(0.0))) + min(max(q.x, q.y), 0.0) - uRadius;
            float inside = 1.0 - smoothstep(-1.0, 0.5, d);

            float2 uv = fragCoord / max(uSize, float2(1.0));
            float rim = 1.0 - smoothstep(-max(uRadius, 1.0) * 0.55, 0.0, d);

            float3 body = uTint * (0.55 + 0.45 * uv.y) * uStrength;

            float2 nrm = normalize(p + float2(0.0001));
            float spec = pow(max(dot(nrm, normalize(uLight)), 0.0), 8.0) * rim;

            float fringe = smoothstep(0.55, 1.0, rim);
            float3 chroma = float3(0.035, 0.0, 0.05) * fringe;

            float grain = fract(sin(dot(fragCoord, float2(12.9898, 78.233))) * 43758.5453) * 0.012;

            float3 color = body + spec * 0.55 + chroma + grain;
            float alpha = inside * clamp(uStrength + 0.18 + spec * 0.5, 0.0, 1.0);
            return half4(half3(color.r, color.g, color.b), half(alpha));
        }
    """
}

/** Paints the shader, or the opaque-gradient fallback below API 33. */
internal fun DrawScope.paintLiquidGlass(tint: Color, strength: Float, radiusPx: Float, lightX: Float) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        runCatching {
            val shader = RuntimeShader(LiquidGlassShader.SOURCE).apply {
                setFloatUniform("uSize", size.width, size.height)
                setFloatUniform("uRadius", radiusPx)
                setFloatUniform("uStrength", strength)
                setFloatUniform("uTint", tint.red, tint.green, tint.blue)
                setFloatUniform("uLight", lightX, 0.42f)
            }
            val paint = Paint().apply {
                isAntiAlias = true
                setShader(shader)
            }
            drawIntoCanvas { canvas ->
                canvas.nativeCanvas.drawRect(0f, 0f, size.width, size.height, paint)
            }
            return
        }
    }
    drawRect(
        brush = Brush.linearGradient(
            listOf(
                tint.copy(alpha = (strength + 0.10f).coerceAtMost(1f)),
                tint.copy(alpha = (strength * 0.55f).coerceAtMost(1f)),
                tint.copy(alpha = (strength * 0.85f).coerceAtMost(1f)),
            ),
            start = Offset.Zero,
            end = Offset(size.width, size.height),
        ),
    )
}

/** Specular hairline that hugs the silhouette, as iOS draws on glass. */
internal fun DrawScope.paintSpecular(radiusPx: Float, dark: Boolean) {
    drawRoundRect(
        brush = Brush.linearGradient(
            listOf(
                Color.White.copy(alpha = if (dark) 0.34f else 0.70f),
                Color.White.copy(alpha = 0.04f),
                Color.White.copy(alpha = if (dark) 0.18f else 0.30f),
            ),
            start = Offset.Zero,
            end = Offset(size.width, size.height * 0.6f),
        ),
        cornerRadius = androidx.compose.ui.geometry.CornerRadius(radiusPx, radiusPx),
        style = Stroke(width = 1f),
    )
}
