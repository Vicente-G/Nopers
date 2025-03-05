PROPS_FILE='./src/main/resources/application.properties'
MILESTONE_REPO='<repository><id>spring-milestones-fb<\/id><name>FB Milestones Repo<\/name><url>https:\/\/repo.spring.io\/milestone\/<\/url><\/repository>'

# Fix the little servlet issue
sed -e 's/>servlet-api</>javax.servlet-api</g' -i ./pom.xml
# Fix the Facebook Social issue
sed -e "s/<\/repositories>/$MILESTONE_REPO<\/repositories>/g" -i ./pom.xml
# Set the database URLs on application.properties
sed -e "s|jdbc:postgresql://localhost:5432/ss_demo_1|$1|g" -i $PROPS_FILE
