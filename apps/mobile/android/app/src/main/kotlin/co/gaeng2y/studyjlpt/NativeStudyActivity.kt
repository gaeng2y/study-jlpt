package co.gaeng2y.studyjlpt

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
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
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

class NativeStudyActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val jp = intent.getStringExtra("jp") ?: ""
        val reading = intent.getStringExtra("reading") ?: ""
        val meaningKo = intent.getStringExtra("meaningKo") ?: ""
        val kind = intent.getStringExtra("kind") ?: "vocab"
        val jlptLevel = intent.getStringExtra("jlptLevel") ?: "N5"

        setContent {
            MaterialTheme {
                NativeStudyScreen(
                    jp = jp,
                    reading = reading,
                    meaningKo = meaningKo,
                    kind = kind,
                    jlptLevel = jlptLevel,
                    onAgain = { finishWith("again") },
                    onGood = { finishWith("good") },
                )
            }
        }
    }

    private fun finishWith(grade: String) {
        setResult(
            Activity.RESULT_OK,
            Intent().putExtra("grade", grade)
        )
        finish()
    }
}

@Composable
private fun NativeStudyScreen(
    jp: String,
    reading: String,
    meaningKo: String,
    kind: String,
    jlptLevel: String,
    onAgain: () -> Unit,
    onGood: () -> Unit,
) {
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
                .padding(20.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(470.dp),
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
        }
    }
}
