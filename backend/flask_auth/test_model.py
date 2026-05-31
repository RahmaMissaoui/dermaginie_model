import requests
import base64

image_path = r'C:\FlutterProjects\app1\assets\images\mel2.PNG'

print("📤 جاري تحميل الصورة...")

with open(image_path, 'rb') as f:
    img_base64 = base64.b64encode(f.read()).decode()

print("📡 جاري إرسال الطلب إلى Flask...")

response = requests.post(
    'http://127.0.0.1:5000/analyze-melanoma',
    json={'image': img_base64}
)

print("📊 النتيجة:\n")

result = response.json()

if result.get('success'):
    print(f"✅ الفئة المتوقعة: {result.get('predicted_label', 'N/A')}")
    print(f"📊 نسبة الثقة: {result.get('confidence', 0):.2%}")
    print("\n📈 جميع الاحتمالات:")
    for cls, prob in result.get('all_probabilities', {}).items():
        bar = '█' * int(prob * 50)
        print(f"  {cls:6s}: {prob:.2%} {bar}")
else:
    print(f"❌ خطأ: {result.get('error', 'Unknown error')}")

print("\n" + "=" * 50)