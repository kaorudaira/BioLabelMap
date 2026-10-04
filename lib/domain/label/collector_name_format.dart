/// 採集者名をラベル用の形にする。`Kaoru Yoshihara` → `K. YOSHIHARA`。
///
/// 入力は「名 姓」の順の英語表記を想定する。最後の語を姓として大文字にし、
/// それより前の語は頭文字+ピリオドにする。すでに `K. Yoshihara` の形なら、
/// 姓を大文字にするだけになる。1語だけなら、その語を大文字にする。
String formatCollectorName(String input) {
  final words = input.trim().split(RegExp(r'\s+'));
  if (words.length == 1) return words.single.toUpperCase();

  final family = words.last.toUpperCase();
  // `.map(...)` は Java の Stream.map、`.join` は Collectors.joining に相当する。
  final initials = words
      .sublist(0, words.length - 1)
      .map((w) => w.endsWith('.') ? w : '${w[0].toUpperCase()}.')
      .join(' ');
  return '$initials $family';
}
