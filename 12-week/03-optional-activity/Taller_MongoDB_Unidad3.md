# Taller Práctico — Unidad 3
## Introducción a Bases de Datos NoSQL (MongoDB)

**Objetivo:** Aplicar los conceptos básicos del modelo de documentos en MongoDB, mediante el diseño de documentos y la formulación de consultas simples.

---

### Actividad 1 — Diseño del documento

**1. ¿Qué información considera adecuado embebir dentro del documento de un equipo?**
Se recomienda embebir la información técnica fija del equipo (marca, modelo, especificaciones), su ubicación actual y, fundamentalmente, el historial de mantenimientos.

**2. ¿Qué información podría separarse en otra colección si el sistema creciera?**
Si el sistema crece, sería conveniente separar la información detallada de los técnicos (especialidad, contacto, horario) y un catálogo maestro de repuestos para gestionar inventarios de forma global.

**Justificación:**
El modelo embebido es ideal para el historial de mantenimiento porque permite recuperar toda la "hoja de vida" del equipo en una sola consulta, evitando *joins* costosos. Dado que los mantenimientos son datos que pertenecen intrínsecamente a la historia de cada equipo y su estructura puede variar (distintos repuestos u observaciones), MongoDB ofrece la flexibilidad necesaria para manejar este crecimiento sin esquemas rígidos.

---

### Actividad 2 — Ejemplo de documento

Ejemplo de un documento JSON representativo para un equipo industrial:

```json
{
  "nombre": "Generador Eléctrico G-502",
  "tipo": "Generador Diesel",
  "ubicacion": "Planta Industrial Sur - Sección A",
  "estado": "Operativo",
  "especificaciones": {
    "potencia": "500kW",
    "marca": "Caterpillar"
  },
  "mantenimientos": [
    {
      "fecha": "2026-02-15",
      "tecnico": "Carlos Rodríguez",
      "observacion": "Cambio de aceite y revisión de niveles de refrigerante.",
      "repuestos_usados": ["Filtro de aceite X1", "Aceite sintético 15W40"]
    },
    {
      "fecha": "2026-04-10",
      "tecnico": "Andrea Méndez",
      "observacion": "Limpieza de inyectores y calibración de voltaje.",
      "repuestos_usados": ["Kit de limpieza inyectores"]
    }
  ]
}
```

---

### Actividad 3 — Consultas básicas

**1. Obtener todos los equipos ubicados en una sede específica:**
```javascript
db.equipos.find({ "ubicacion": "Planta Industrial Sur - Sección A" })
```

**2. Buscar equipos cuyo nombre contenga una palabra clave (uso de $regex):**
```javascript
db.equipos.find({ "nombre": { "$regex": "Generador", "$options": "i" } })
```

**3. Consultar equipos que tengan al menos un mantenimiento realizado por un técnico específico:**
```javascript
db.equipos.find({ "mantenimientos.tecnico": "Andrea Méndez" })
```

---

### Actividad 4 — Actualización simple

**1. Cambiar el estado de un equipo:**
```javascript
db.equipos.updateOne(
  { "nombre": "Generador Eléctrico G-502" },
  { "$set": { "estado": "En Mantenimiento" } }
)
```

**2. Agregar un nuevo registro de mantenimiento al arreglo de mantenimientos:**
```javascript
db.equipos.updateOne(
  { "nombre": "Generador Eléctrico G-502" },
  { 
    "$push": { 
      "mantenimientos": {
        "fecha": "2026-04-30",
        "tecnico": "Ricardo Soto",
        "observacion": "Revisión preventiva de bornes de batería."
      }
    } 
  }
)
```

---

### Actividad 5 — Reflexión breve

**¿Por qué el modelo de documentos es adecuado para este tipo de información?**
Es adecuado porque permite agrupar datos relacionados (como el historial de mantenimiento) en una sola estructura lógica que crece de forma natural. Al no tener un esquema rígido, cada registro de mantenimiento puede contener información distinta (diferentes tipos de repuestos o campos adicionales) sin afectar a los demás documentos.

**¿Qué ventaja ofrece frente a un modelo relacional en este caso?**
La principal ventaja es el rendimiento en la lectura de la historia del equipo y la flexibilidad. En un modelo relacional, se requerirían múltiples tablas y uniones (*joins*) para reconstruir la información, mientras que en MongoDB se obtiene el objeto completo con sus mantenimientos en una única operación atómica, simplificando además la evolución del modelo ante nuevos requerimientos de datos.
