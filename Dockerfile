# Use a minimal base image for building
FROM gradle:7.3.3-jdk11 AS build

# Set the working directory
WORKDIR /Jnekins-OC-Project

# Copy only the build files needed for dependency resolution
COPY build.gradle settings.gradle ./

# Download and resolve dependencies using the Gradle Wrapper
COPY gradlew .
COPY gradle gradle
# Give execute permissions to the Gradle wrapper
RUN chmod +x ./gradlew
RUN ./gradlew dependencies

# Copy the rest of the source code
COPY . .

RUN chmod +x ./gradlew
# Build the application using the Gradle Wrapper
RUN ./gradlew build --stacktrace

# Use a minimal base image for the runtime
FROM adoptopenjdk:11-jre-hotspot

# Set the working directory
WORKDIR /Jnekins-OC-Project

# Copy the JAR file from the build stage
COPY --from=build /Jnekins-OC-Project/build/libs/demo-0.0.1-SNAPSHOT.jar app.jar

# Expose the port your app runs on
EXPOSE 8081

# Define the command to run your application
CMD ["java", "-jar", "app.jar"]
