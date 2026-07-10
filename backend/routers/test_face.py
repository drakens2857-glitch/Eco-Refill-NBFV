import cv2

# 🔹 Cargar clasificador Haar (ya viene con OpenCV)
face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + "haarcascade_frontalface_default.xml")

# 🔹 Cargar imagen de prueba
img = cv2.imread("foto.jpg")  # reemplaza con el nombre de tu imagen
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# 🔹 Detectar rostros
faces = face_cascade.detectMultiScale(gray, scaleFactor=1.3, minNeighbors=5)

print(f"Se detectaron {len(faces)} rostros")

# 🔹 Dibujar rectángulos
for (x, y, w, h) in faces:
    cv2.rectangle(img, (x, y), (x+w, y+h), (0, 255, 0), 2)

# 🔹 Guardar resultado
cv2.imwrite("resultado.jpg", img)
