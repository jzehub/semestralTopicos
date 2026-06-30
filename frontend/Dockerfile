FROM nginx:alpine

ARG API_BASE_URL=http://localhost:5000

COPY index.html /usr/share/nginx/html/
COPY styles.css /usr/share/nginx/html/
COPY app.js /usr/share/nginx/html/

RUN sed -i "s|__API_BASE_URL__|${API_BASE_URL}|g" /usr/share/nginx/html/index.html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]