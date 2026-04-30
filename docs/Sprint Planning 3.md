

**Happy Family Sim**

**Sprint 3 Planning Document**  
Team 21: Joanna Lin, Taylor Huang, William Hou, Zoey Lu

## **Sprint Overview:**

After establishing the foundational architecture in Sprint 2, we aim to build more advanced features and improve the overall user experience in this sprint, including the UI, the gaming part, and task creation, assignment, submission, and review. Task completion and gaming are connected by adding the reward feature. Key deliverables include:

* **Task Assignment**: Enabling parents to choose from a set of pre-populated tasks and assign a task to multiple children.   
* **Reviewing Tools and Rewards**: Allowing the children to submit completed tasks for review. Parents are able to reject or accept a task and decide what kind of resources to give their children upon the acceptance of a task.  
* **Game**: Implementing more advanced AI for the pet, allowing for cosmetic reward boxes when completing tasks, and polishing the game aspect to be more attractive to users.

By the end of this sprint, the team aims to have a complete pipeline where a parent can assign and review a chore and a child can interact with their creature within the integrated game engine.

## **Scrum Master:** Joanna Lin

## **Meeting Schedule:** MWF at 7 PM

## **Risks and Challenges:**

- Implementing a notification system and allowing redirection to the respective page in the app when the user clicks the notification may be challenging  
- The AI system for the pet would involve complicated state machine logic.

# **Current Sprint Detail**

## **Task Creation & Assignment (Parent):**

**User Story \#2-6 (from previous sprint)**  
As a parent, I would like to assign a task to multiple children simultaneously, letting each child have their individual version of the assigned task.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Update task creation, task list, and error message UI to enable multiple assignees | 3 Hrs | Joanna |
| 2 | Develop backend logistics for creating separate tasks for each assigned child and save to the database | 3 Hrs | Joanna |
| 3 | Test: debug and test functionalities with manual testing (checking if the database reflect) | 2 Hrs | Joanna |

Acceptance criteria:

1. Given the parent is creating or editing a task and has multiple linked children, when they open the assignee selector, then the UI allows selecting multiple children and clearly shows which children are selected.  
2. Given the parent selects more than one child and clicks “Save,” when the request is processed, then the system creates a separate child-specific task instance for each selected child (each with its own unique task record) using the same task details.  
3. Given the parent attempts to save a task with no children selected, when they click “Save,” then the system blocks submission and displays an error message indicating that at least one child must be selected.  
4. Given the parent returns to the task list after saving, when the task list loads or refreshes, then the UI displays the assigned tasks for each child in a way that makes it clear each child has their own version.

**User Story \#2-14 (from previous sprint)**  
As a parent, I would like to choose a task to assign from a list of preset tasks.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Create a list of common tasks. | 2 Hrs | Zoey |
| 2 | Design UI to choose from the preset. | 2 Hrs | Zoey |
| 3 | Test: debug and test functionalities with manual testing. | 2 Hrs | Zoey |

Acceptance criteria:

1. As a parent, I should be able to see a list of preset tasks when I am creating a task.  
2. Clicking on a preset task should auto-populate fields such as the name of the task.  
3. Parents should be able to assign a preset task to children, just like a self-made one.

**User Story \#2-9**  
As a parent, I would like to be able to require photo evidence for a task to be marked as complete.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Update the backend so that tasks can be marked whether they require photo evidence or not | 2 Hrs | Zoey |
| 2 | Update the UI so that parents can choose whether photo evidence is required when creating a task | 2 Hrs | Zoey |
| 3 | Redesign the UI so that photo evidence can be displayed properly. | 2 Hrs | Zoey |
| 3 | Test: debug and test functionalities with manual testing. | 2 Hrs | Zoey |

Acceptance criteria:

1. Given that the backend is updated correctly, when a parent creates or edits a task, then they should be able to specify whether photo evidence is required.  
2. Given that the UI is implemented correctly, when a parent is creating a task, then they should be able to select an option to require photo evidence.  
3. Given that a task requires photo evidence, when a child attempts to mark the task as complete, then they must provide a photo before submission.  
4. Given that a task does not require photo evidence, when a child marks the task as complete, then they should be able to submit it without uploading a photo.  
5. Given that photo evidence is submitted, when the task is viewed, then the photo should be displayed correctly in the UI.

**User Story \#2-12**  
As a parent, I would like to create and name custom categories to organize tasks (e.g., "School," "Hygiene").

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Design UI, allowing the user to add categories and filter based on the categories | 2 Hrs | Joanna |
| 2 | Update the database for the feature and implement the logistics in the backend | 3 Hrs | Joanna |
| 3 | Test: debug and test functionalities with manual testing. | 2 Hrs | Joanna |

Acceptance criteria:

1. Given the parent is logged in and on the category management interface, when they enter a valid category name (such as “School” or “Hygiene”) and click “Create,” then the system creates the new custom category and displays it in the category list.  
2. Given the parent attempts to create a category with an empty, invalid, or duplicate name, when they click “Create,” then the system blocks the submission and displays a clear validation message explaining the issue.  
3. Given one or more custom categories exist, when the parent views task organization or filtering options, then the created categories appear as available options for organizing and filtering tasks.  
4. Given the parent selects a category filter, when the task list is updated, then only tasks associated with the selected category or categories are displayed, matching the database state.

**User Story \#2-15**  
As a parent, I would like to see an intuitive task view, allowing me to see tasks each day.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Design UI, allowing a more intuitive daily view rather than long list | 3 Hrs | Joanna |
| 2 | Refactor the current UI for task view, including organizing reusable components into model | 5 Hrs | Joanna |
| 3 | Test: debug and test functionalities with manual testing. | 2 Hrs | Joanna |

Acceptance criteria:

1. Given the parent is logged in and navigates to the task view page, when the page loads, then the system displays tasks in an intuitive daily view grouped by day instead of only showing one long undifferentiated list.  
2. Given tasks exist for a specific day, when the parent selects or views that day, then the UI displays all tasks due or scheduled for that day with key task details clearly visible.  
3. Given no tasks exist for a selected day, when the parent opens that day’s view, then the system displays a clear empty-state message indicating there are no tasks for that day.  
4. Given a task is created, edited, or deleted, when the parent returns to or refreshes the daily task view, then the daily view reflects the updated task data accurately without showing outdated information.

## **Task Viewing & Submission (Child):**

**User Story \#3-5**  
As a child, I would like to take and upload a new photo as evidence for a required task and retake the photo if I don’t like it.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Create the pop-up UI to take photo and view the photo | 3 Hrs | Taylor |
| 2 | Update the backend logic so it’ll be able to store the image and submit for approval | 3 Hrs | Taylor |
| 5 | Test manually | 1.5 Hrs | Taylor |

Acceptance criteria:

1. Given the child marks the tasks done, for those tasks that required a photo proof. The pop-up message will show up and provide a button for them to take a photo and display the photo they take.  
2. Given the child doesn't like the photo they take, they can hit the retake photo button to retake it.  
3. The child then can proceed the proof with a submit button or cancel button to abort the submission.  
4. Given the child proceeds with a submit button, the task will be marked as done and waiting for parent approval.

**User Story \#3-6**  
As a child, I would like to receive a notification when a task is going to expire in an hour.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Design the logic to check the time left till expiration of tasks | 3 Hrs | Zoey |
| 2 | Implement the notification | 2 Hrs | Zoey |
| 4 | Test manually | 2 Hrs | Zoey |

Acceptance criteria:

1. Given a task is scheduled to expire in exactly one hour, when the scheduled job runs, then the child receives a clear and distinct in-app notification before the deadline.  
2. Given a notification is received, when the child taps on it, then they are directed to the details of the expiring task.  
3. Given the notification system is functioning, when the task is already completed or approved, then no expiration notification should be sent.

**User Story \#3-7**  
As a child, I would like to see an intuitive task view designed for children, allowing me to see tasks each day and having clear fonts and colors.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Design UI, allowing a more intuitive daily view rather than long list | 3 Hrs | Joanna |
| 2 | Refactor the current UI for task view, adjusting fonts sizes and appeal to make the view more attractive to children | 4 Hrs | Joanna |
| 3 | Test: debug and test functionalities with manual testing. | 2 Hrs | Joanna |

Acceptance criteria:

1. Given the child is logged in and opens the task page, when the page loads, then the system displays tasks in a daily view grouped by day instead of a long list.  
2. Given the child is viewing a specific day, when tasks exist for that day, then the UI displays all tasks for that day using clear fonts, readable text sizes, and visually distinct colors that are easy for children to understand.  
3. Given the child is viewing a specific day, when no tasks are assigned for that day, then the system displays a simple and child-friendly empty-state message indicating that there are no tasks for that day.  
4. Given the task view has been redesigned for children, when the child navigates through their daily tasks, then the interface remains visually consistent and easy to read across screens and components.

## **Task Approval & History (Parent & Child):**

## 

**User Story \#4-2**  
As a parent, I would like to view the submitted photo evidence for a task.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Create the UI under the pending task details | 1.5 Hrs | Taylor |
| 2 | Update the backend for fetching the details information for the pending task | 1.5 Hrs | Taylor |
| 3 | Test manually | 1.5 Hrs | Taylor |

Acceptance criteria:

1. As a parent, for the task that required photo evidence I should be able to see a section for displaying the submitted photo under the pending details.  
2. For those tasks that don’t require the proof I won’t be able to see the evidence section.  
3. I can also click on the photo to zoom in and out.

**User Story \#4-6**  
As a child, I would like to receive a notification when a task submission is approved.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Design the logic in the backend to reflect the states of a task, such as approved, declined, submitted, assigned. | 3 Hrs | Zoey |
| 2 | Implement the notification. | 2 Hrs | Zoey |
| 3 | Test manually | 2 Hrs | Zoey |

Acceptance criteria:

1. Given a parent successfully approves a task submission, when the approval is recorded in the database, then the corresponding child immediately receives a notification of the approval.  
2. Given the notification is received, when the child taps on it, then they are taken to view the completed task.  
3. Given the backend task state logic is implemented correctly, when a task status changes to approved, then the system sends the approval notification only to the child assigned to that task.  
4. Given a task is not approved, when its status remains assigned, submitted, or declined, then the child does not receive an approval notification for that task.

**User Story \#4-7**  
As a child, I would like to receive a notification, including parent feedback, when a task submission is rejected.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Implement the notification | 1 Hrs | Zoey |
| 2 | Get the feed back from the database, and present it in the notification. | 2 Hrs | Zoey |
| 3 | Test manually | 2 Hrs | Zoey |

Acceptance criteria:

1. Given a parent successfully rejects a task submission and provides text feedback, when the rejection is recorded, then the corresponding child immediately receives a notification detailing the rejection.  
2. Given the notification is received, when the child taps on it, then they are taken to view the rejected task.  
3. Given the backend task state logic is implemented correctly, when a task status changes to rejected, then the system sends the approval notification only to the child assigned to that task.

**User Story \#4-8**  
As a parent/child, I would like to view a historical log of all tasks completed, missed, or rejected.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Create the UI for parent app | 3 Hrs | Joanna |
| 2 | Create the backend logic to fetch the tasks for parent app | 3 Hrs | Joanna |
| 3 | Create the UI for child app | 4 Hrs | Taylor |
| 4 | Create the backend logic to fetch the tasks for child app | 4 Hrs | Taylor |
| 5 | Test manually for parent | 1 Hrs | Joanna |
| 6 | Test manually for child | 1.5 Hrs | Taylor |

Acceptance criteria:

1. Given a parent/child navigates to the Task History screen, they should be able to view a chronological list of all tasks.  
2. Each historical task entry must clearly show the task name, the final status (Completed, Missed, or Rejected), and the completion/rejection/missed date.  
3. As a parent, I should be able to filter the historical log by individual children and the status of the tasks.  
4. As a child, I should be able to filter historical log by the status of the tasks.  
5. As a parent/child, I will be able to see the details of that task when I click on it.  
   

**User Story \#4-9**  
As a parent, I would like to view a report showing the task completion rate for each child over the last week/month.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Research and play around on which plot is better for displaying the completion rate for the child | 2 Hrs | Taylor |
| 2 | Create the UI to display the report for the task completion rate | 3 Hrs | Taylor |
| 3 | Create the backend logic to fetch the completion rate for each child | 3 Hrs | Taylor |
| 5 | Test manually | 1.5 Hrs | Taylor |

Acceptance criteria:

1. Given a parent views the report, they should be able to select a time frame (last week or last month).  
2. The report must accurately display the percentage of tasks completed versus total tasks assigned to the selected child within the chosen time frame.  
3. Given there is more than one child, the parent should be able to view the report for each child individually.

**User Story \#4-10**  
As a parent, I would like to view simple statistics of task completions across all the categories.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Create the UI page for parent to interact with | 3 Hrs | Taylor |
| 2 | Create the backend logic to aggregate the data and transform into graph |  3 Hrs | Taylor |
| 3 | Integrate the frontend and backend | 2 Hrs | Taylor |
| 5 | Test manually | 1.5 Hrs | Taylor |

Acceptance criteria:

1. The statistics dashboard must display a clear list or graph showing the tasks with the highest rate of completion and the tasks with the highest rate of failure/rejection.  
2. The data used for statistics should be based on historical task occurrences across all children.  
3. Given the parent views the statistics, the data should be presented in a way that helps inform reward adjustment decisions.

## **Gamification & Creature Care:**

**User Story \#5-4**  
As a child, I would like to see my creature's status (hygiene, hunger, hydration) slowly deplete over time.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Configure the background logic to calculate and apply status reductions based on elapsed time. | 4 Hrs | William |
| 2 | Implement the data sync between the background depletion logic and the Supabase database. | 4 Hrs | William |
| 3 | Develop a system to handle status updates when the application is closed or in the background. | 5 Hrs | William |
| 4 | **Testing**: Verify that status levels decrease at the intended rate over a set period. | 3 Hrs | William |

Acceptance Criteria:

1. Given the game is active, when time passes, then the creature's hunger, hygiene, and hydration status bars must decrease at a consistent, predefined rate.  
2. Given the app is reopened after being closed, when the state is fetched, then the status levels must accurately reflect the depletion that occurred while the app was inactive.  
3. Given a status bar reaches its minimum value, when further depletion is calculated, then the value must stay at zero and not become a negative number.

   

   

   

   

 


**User Story \#5-6**  
As a child, I would like to be able to open a mystery box (cosmetic items, resources, etc) under certain conditions.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Develop the logic to define and track the specific conditions or milestones required to earn a mystery box. | 4 Hrs | William |
| 2 | Design the interface and user interaction flow for the mystery box opening sequence. | 4 Hrs | William |
| 3 | Implement the randomized reward logic to determine the contents (resources or cosmetic items) of the box. | 5 Hrs | William |
| 4 | Create the animations and visual feedback associated with receiving and opening a box in the game engine. | 5 Hrs | William |
| 5 | **Testing**: Verify that rewards are correctly added to the child's inventory following the opening sequence. | 2 Hrs | William |

Acceptance Criteria:

1. Given the child has met a predefined goal (e.g., a specific number of completed tasks), when they enter the game, then a mystery box must be available for them to open.  
2. Given the mystery box is opened, when the reward is revealed, then the system must display the specific item or resource granted.  
3. Given a reward is granted, when the sequence finishes, then the item must be immediately functional or visible in the child's inventory.

**User Story \#5-7**  
As a child, I would like my virtual pet to have autonomous behaviors and a life cycle (like sleeping and wandering) so that it feels like a living creature.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Implement a "Wander" state machine in Flame to allow the pet to move to random coordinates within room bounds.  | 5 Hrs | William |
| 2 | Develop a system that transitions the pet into a "Sleep" state. | 4 Hrs | William |
| 3 | Design and implement visual assets and animations for "Walking," "Sleeping,", and ambient effects. | 5 Hrs | William |
| 4 | Create touch-detection logic to trigger specific "Reaction" animations and interrupt autonomous states when tapped. | 4 Hrs | William |
| 7 | Create a "Save State" function to persist the pet's last known position and current AI state in the database. | 4 Hrs | William |
| 8 | **Test**: Verify that the pet transitions correctly between all AI states (Idle, Wander, Sleep, React) and react accordingly to touch. | 3 Hrs | William |

Acceptance Criteria

1. Given the pet is in the game environment, when it is in an idle state, then it should occasionally choose a new location and play a walking animation to move there autonomously.  
2. Given the child taps on the pet while it is awake, when the touch event is registered, then the pet must immediately play a unique reaction animation.  
3. Given the pet is sleeping, when the child attempts to interact, then the system should provide a subtle visual hint indicating the pet is resting.

## **UI & Aesthetics:**

**User Story \#6-3**  
Update icons so that they match the overall aesthetic.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Redesign the icons for the parents' part | 3 Hrs | Zoey |
| 2 | Apply the new icons | 4 Hrs | Zoey |
| 3 | Redesign the icons for the children' s part. Replace long texts with understandable icons. | 3 Hrs | Zoey |

Acceptance criteria:

1. Given that the icons for the parents’ part are redesigned correctly, when parents use the app, then all icons should be clear, consistent, and aligned with the overall app aesthetic.  
2. Given that the new icons are applied correctly, when navigating through the app, then all relevant pages should display the updated icons without missing or broken elements.  
3. Given that consistency is required, when comparing different parts of the app, then icon styles (color, size, and design language) should remain uniform across all pages.

## 

## 

## **Current Total Hours:** 175.5 Hrs

| Name | Estimated Time |
| :---: | :---: |
| Taylor | 40.5 Hrs |
| William | 51 Hrs |
| Zoey | 43 Hrs |
| Joanna | 41 Hrs |

# **Remaining Backlog**

**User Account & Authentication:**

1. ~~As a parent, I would like to create a new parent account.~~  
2. ~~As a parent, I would like to securely log in using email and a password.~~  
3. ~~As a parent, I would like to securely log out of my account.~~  
4. ~~As a parent, I would like to reset my password if I forget it.~~  
5. ~~As a parent, I would like to manage/edit my parent profile.~~  
6. ~~As a parent, I would like to view a list of all linked child accounts.~~  
7. ~~As a parent, I would like to create a new child account for my child.~~  
8. As a parent, I would like to link a child's account to my parent profile.  
9. ~~As a child, I would like to securely log in using the same email as my parent account and a 6-digit code provided by my parents.~~

**Task Creation & Assignment (Parent):**

1. ~~As a parent, I would like to create a custom task with a unique title and detailed description.~~  
2. ~~As a parent, I would like to set a specific due date for a task.~~  
3. ~~As a parent, I would like to set a task to repeat on a daily, weekly, or custom frequency (recurring task).~~  
4. ~~As a parent, I would like to set a task as a one-off, non-recurring task.~~  
5. ~~As a parent, I would like to assign a task to a single child.~~  
6. As a parent, I would like to assign a task to multiple children simultaneously.  
7. ~~As a parent, I would like to specify the type of resource (e.g., Water, Food, Hygiene) as a reward.~~  
8. ~~As a parent, I would like to specify the amount of the resource reward for task completion.~~  
9. As a parent, I would like to be able to require photo evidence for a task to be marked as complete.  
10. ~~As a parent, I would like to edit the details of an existing task.~~  
11. ~~As a parent, I would like to delete an existing task.~~  
12. As a parent, I would like to create and name custom categories to organize tasks (e.g., "School," "Hygiene").  
13. ~~As a parent, I would like to view a list of all created and active tasks.~~  
14. As a parent, I would like to choose a task to assign from a list of preset tasks.  
15. As a parent, I would like to see an intuitive task view, allowing me to see tasks each day.

**Task Viewing & Submission (Child):**

1. ~~As a child, I would like to view a list of all tasks currently assigned to me.~~  
2. ~~As a child, I would like the list of tasks to display the due date.~~  
3. ~~As a child, I would like to select a task to view its full title, description, and required reward.~~  
4. ~~As a child, I would like to mark a task as complete to submit it for parent approval.~~  
5. As a child, I would like to take and upload a new photo as evidence for a required task.  
6. As a child, I would like to receive a notification when a task is going to expire in an hour.  
7. As a child, I would like to see an intuitive task view designed for children, allowing me to see tasks each day and having clear fonts and colors.

**Task Approval & History (Parent & Child):**

1. ~~As a parent, I would like to view a dashboard listing all task submissions pending my approval.~~  
2. As a parent, I would like to view the submitted photo evidence for a task.  
3. ~~As a parent, I would like to approve a completed task submission.~~  
4. ~~As a parent, I would like to reject a completed task submission.~~  
5. ~~As a parent, I would like to enter text feedback when rejecting a task submission.~~  
6. As a child, I would like to receive a notification when a task submission is approved.  
7. As a child, I would like to receive a notification, including parent feedback, when a task submission is rejected.  
8. As a parent/child, I would like to view a historical log of all tasks completed, missed, or rejected.  
9. As a parent, I would like to view a report showing the task completion rate for each child over the last week/month.  
10. As a parent, I would like to view simple statistics of task completions, figuring what task is complete/miss the most to adjust reward when assigning tasks.

**Gamification & Creature Care:**

1. ~~As a child, I would like to see my total accumulated amount for each resource type (Water, Food, Hygiene, etc).~~  
2. ~~As a child, I would like to access the game environment to view my virtual creature.~~  
3. ~~As a child, I would like to select a resource type to apply to my creature/environment.~~  
4. As a child, I would like to see my creature's status (hygiene, hunger, hydration) slowly deplete over time.  
5. ~~As a child, I would like to see visual feedback (e.g., an animated "sad" state) when the creature's status drops too low.~~  
6. As a child, I would like to be able to open a mystery box (cosmetic items, resources, etc) under certain conditions.  
7. As a child, I would like my virtual pet to have autonomous behaviors and a life cycle (like sleeping and wandering) so that it feels like a living creature.  
8. ~~As a child, I would like to see available cosmetic items, unlock them, and place/edit their positions in the environment.~~

**UI & Aesthetics:**

1. ~~The aesthetic throughout the app should be consistent. Such as the color scheme, background, and font.~~  
2. ~~Create a logo for our app, and add it to the corresponding places.~~  
3. Update icons so that they match the overall aesthetic.