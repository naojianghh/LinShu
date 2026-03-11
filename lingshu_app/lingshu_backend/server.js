import express from 'express';
import cors from 'cors';

const app = express();
const PORT = process.env.PORT || 8787;

app.use(cors());
app.use(express.json());

const tracks = [
  {
    id: 'gong-1',
    tone: '宫音',
    title: '宫音·安脾调息',
    artist: 'LingShu Healing',
    audio_url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    cover_url: '',
    lyric: '呼吸放缓，意守中焦，让身体回归稳定与松弛。',
  },
  {
    id: 'gong-2',
    tone: '宫音',
    title: '宫音·中和之律',
    artist: 'LingShu Healing',
    audio_url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    cover_url: '',
    lyric: '沉稳柔和的节奏，帮助舒缓焦虑、安定心神。',
  },
  {
    id: 'shang-1',
    tone: '商音',
    title: '商音·清肃晨风',
    artist: 'LingShu Healing',
    audio_url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    cover_url: '',
    lyric: '如晨风拂面，轻清入肺，唤醒清朗状态。',
  },
  {
    id: 'shang-2',
    tone: '商音',
    title: '商音·润燥平衡',
    artist: 'LingShu Healing',
    audio_url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
    cover_url: '',
    lyric: '音色清透舒展，帮助调整呼吸节律。',
  },
  {
    id: 'jue-1',
    tone: '角音',
    title: '角音·疏肝流云',
    artist: 'LingShu Healing',
    audio_url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
    cover_url: '',
    lyric: '让情绪像云一样流动，渐渐舒展，不再郁结。',
  },
  {
    id: 'jue-2',
    tone: '角音',
    title: '角音·木气舒展',
    artist: 'LingShu Healing',
    audio_url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3',
    cover_url: '',
    lyric: '旋律层层展开，帮助放松胸胁与心绪。',
  },
  {
    id: 'zhi-1',
    tone: '徵音',
    title: '徵音·暖阳养心',
    artist: 'LingShu Healing',
    audio_url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
    cover_url: '',
    lyric: '温暖明亮的旋律，陪你沉静、专注、安心。',
  },
  {
    id: 'zhi-2',
    tone: '徵音',
    title: '徵音·赤霞宁神',
    artist: 'LingShu Healing',
    audio_url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3',
    cover_url: '',
    lyric: '如暮色暖光，渐渐收拢杂念。',
  },
  {
    id: 'yu-1',
    tone: '羽音',
    title: '羽音·静水归藏',
    artist: 'LingShu Healing',
    audio_url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
    cover_url: '',
    lyric: '如夜色下的静水，收摄心气，安稳入静。',
  },
  {
    id: 'yu-2',
    tone: '羽音',
    title: '羽音·深泉安眠',
    artist: 'LingShu Healing',
    audio_url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
    cover_url: '',
    lyric: '低缓而深沉，帮助身心沉降放松。',
  },
];

app.get('/health', (_req, res) => {
  res.json({ ok: true, service: 'lingshu-backend' });
});

app.get('/five-tone/tracks', (req, res) => {
  const { tone } = req.query;

  if (!tone || typeof tone !== 'string') {
    return res.status(400).json({
      message: '缺少 tone 参数，例如 /five-tone/tracks?tone=宫音',
    });
  }

  const result = tracks.filter((item) => item.tone === tone);

  return res.json({
    data: result,
  });
});

app.listen(PORT, () => {
  console.log(`lingshu backend running at http://localhost:${PORT}`);
});

