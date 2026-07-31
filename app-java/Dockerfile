FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /build
COPY pom.xml .
RUN mvn -B -q dependency:go-offline
COPY src ./src
RUN mvn -B -q clean package -DskipTests


FROM gcr.io/distroless/java21-debian12:nonroot
WORKDIR /app
COPY --from=build /build/target/app.jar /app/app.jar
USER 65532:65532
EXPOSE 8080
# The distroless java base has ENTRYPOINT ["/usr/bin/java", "-jar"].
CMD ["/app/app.jar"]
