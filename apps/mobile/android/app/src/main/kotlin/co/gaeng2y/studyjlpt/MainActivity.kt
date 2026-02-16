package co.gaeng2y.studyjlpt

import android.content.Context
import android.view.View
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.consume
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.draw.alpha
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import kotlinx.coroutines.launch
import kotlin.math.roundToInt
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugin.common.StandardMessageCodec

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val eventChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "studyjlpt/native_study"
        )

        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory(
                "studyjlpt/native_study_view",
                NativeStudyPlatformViewFactory(eventChannel)
            )
    }
}

private class NativeStudyPlatformViewFactory(
    private val eventChannel: MethodChannel
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val values = (args as? Map<*, *>) ?: emptyMap<String, Any?>()
        return NativeStudyPlatformView(context, viewId, values, eventChannel)
    }
}

private class NativeStudyPlatformView(
    context: Context,
    private val viewId: Int,
    values: Map<*, *>,
    private val eventChannel: MethodChannel
) : PlatformView {
    private val composeView = ComposeView(context)

    init {
        val contentId = values["contentId"] as? String ?: ""
        val jp = values["jp"] as? String ?: ""
        val reading = values["reading"] as? String ?: ""
        val meaningKo = values["meaningKo"] as? String ?: ""
        val kind = values["kind"] as? String ?: "vocab"
        val jlptLevel = values["jlptLevel"] as? String ?: "N5"

        composeView.setContent {
            MaterialTheme(colorScheme = lightColorScheme()) {
                NativeEmbeddedStudyCard(
                    jp = jp,
                    reading = reading,
                    meaningKo = meaningKo,
                    kind = kind,
                    jlptLevel = jlptLevel,
                    onAgain = {
                        eventChannel.invokeMethod(
                            "onGrade",
                            mapOf("grade" to "again", "contentId" to contentId, "viewId" to viewId)
                        )
                    },
                    onGood = {
                        eventChannel.invokeMethod(
                            "onGrade",
                            mapOf("grade" to "good", "contentId" to contentId, "viewId" to viewId)
                        )
                    }
                )
            }
        }
    }

    override fun getView(): View = composeView

    override fun dispose() = Unit
}

@Composable
private fun NativeEmbeddedStudyCard(
    jp: String,
    reading: String,
    meaningKo: String,
    kind: String,
    jlptLevel: String,
    onAgain: () -> Unit,
    onGood: () -> Unit
) {
    val dragX = remember { Animatable(0f) }
    val scope = rememberCoroutineScope()
    var deciding by remember { mutableStateOf(false) }
    val swipeThreshold = 120f
    val againAlpha = ((-dragX.value) / swipeThreshold).coerceIn(0f, 1f)
    val goodAlpha = ((dragX.value) / swipeThreshold).coerceIn(0f, 1f)

    Surface(
        modifier = Modifier
            .fillMaxSize()
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(Color(0xFFFFF3E8), Color(0xFFEFF9FF))
                )
            )
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(20.dp)
                .offset { IntOffset(dragX.value.roundToInt(), 0) }
                .graphicsLayer(rotationZ = dragX.value / 22f)
                .pointerInput(Unit) {
                    detectDragGestures(
                        onDrag = { change, dragAmount ->
                            if (deciding) return@detectDragGestures
                            change.consume()
                            scope.launch {
                                dragX.snapTo(dragX.value + dragAmount.x)
                            }
                        },
                        onDragEnd = {
                            if (deciding) return@detectDragGestures
                            val x = dragX.value
                            if (x <= -swipeThreshold) {
                                deciding = true
                                scope.launch {
                                    dragX.animateTo(-900f, tween(durationMillis = 140))
                                    onAgain()
                                    dragX.snapTo(0f)
                                    deciding = false
                                }
                                return@detectDragGestures
                            }
                            if (x >= swipeThreshold) {
                                deciding = true
                                scope.launch {
                                    dragX.animateTo(900f, tween(durationMillis = 140))
                                    onGood()
                                    dragX.snapTo(0f)
                                    deciding = false
                                }
                                return@detectDragGestures
                            }
                            scope.launch {
                                dragX.animateTo(0f, spring())
                            }
                        }
                    )
                },
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
            ) {
                Text(
                    text = "AGAIN",
                    color = Color(0xFFC62828),
                    modifier = Modifier.alpha(againAlpha),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Black,
                )
                Text(
                    text = "GOOD",
                    color = Color(0xFF1B7A46),
                    modifier = Modifier.alpha(goodAlpha),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Black,
                )
            }
            Spacer(modifier = Modifier.height(8.dp))
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(360.dp),
                shape = RoundedCornerShape(24.dp),
                elevation = CardDefaults.cardElevation(defaultElevation = 8.dp),
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(22.dp)
                ) {
                    Text(
                        text = "$kind · $jlptLevel",
                        style = MaterialTheme.typography.labelLarge,
                        color = Color(0xFF2A6EEC),
                    )
                    Spacer(modifier = Modifier.weight(1f))
                    Text(
                        text = jp,
                        style = MaterialTheme.typography.displayLarge,
                        fontWeight = FontWeight.Black,
                    )
                    Spacer(modifier = Modifier.height(10.dp))
                    Text(text = reading, style = MaterialTheme.typography.headlineSmall)
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(text = meaningKo, style = MaterialTheme.typography.titleLarge)
                    Spacer(modifier = Modifier.weight(1f))
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                OutlinedButton(
                    modifier = Modifier.weight(1f),
                    onClick = onAgain,
                ) {
                    Text("Again")
                }
                Button(
                    modifier = Modifier.weight(1f),
                    onClick = onGood,
                ) {
                    Text("Good")
                }
            }
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "왼쪽 스와이프 Again · 오른쪽 스와이프 Good",
                style = MaterialTheme.typography.bodySmall,
                color = Color(0xFF5E6978),
            )
        }
    }
}
