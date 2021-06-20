# Build Stage
FROM node:lts-alpine as build-stage
WORKDIR /tmp/app
COPY frontend/package*.json ./
RUN npm install
COPY ./frontend .
RUN npm run build

# Production Stage
FROM nginx:stable-alpine as production-stage
COPY --from=build-stage /tmp/app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]