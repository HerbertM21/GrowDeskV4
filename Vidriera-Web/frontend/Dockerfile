# Dockerfile para Vidriera Web (Astro)
FROM node:18-alpine as builder

WORKDIR /app

# Copiar package.json y package-lock.json
COPY package*.json ./

# Instalar dependencias
RUN npm ci

# Copiar el código fuente
COPY . .

# Construir la aplicación
RUN npm run build

# Etapa de producción
FROM nginx:alpine

# Configurar Nginx para servir archivos estáticos y manejar rutas
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/

# Copiar los archivos construidos
COPY --from=builder /app/dist /usr/share/nginx/html

# Copiar archivos del widget al directorio público
COPY --from=builder /app/public /usr/share/nginx/html

# Exponer el puerto
EXPOSE 4321

# Comando para ejecutar nginx
CMD ["nginx", "-g", "daemon off;"] 