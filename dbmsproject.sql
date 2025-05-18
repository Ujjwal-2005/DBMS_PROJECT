CREATE DATABASE college_event_mgmt;
USE college_event_mgmt;

CREATE TABLE students (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    branch VARCHAR(50),
    year INT,
    phone VARCHAR(15)
);

CREATE TABLE events (
    event_id INT AUTO_INCREMENT PRIMARY KEY,
    event_name VARCHAR(100) NOT NULL,
    event_date DATE NOT NULL,
    location VARCHAR(100),
    seat_limit INT NOT NULL,
    available_seats INT NOT NULL
);

CREATE TABLE registrations (
    reg_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT,
    event_id INT,
    reg_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE,
    CONSTRAINT unique_registration UNIQUE(student_id, event_id)
);

CREATE TABLE faculty (
    faculty_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    department VARCHAR(100),
    email VARCHAR(100) UNIQUE
);

CREATE TABLE event_coordinators (
    coordinator_id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT,
    faculty_id INT,
    FOREIGN KEY (event_id) REFERENCES events(event_id),
    FOREIGN KEY (faculty_id) REFERENCES faculty(faculty_id),
    CONSTRAINT unique_coordinator UNIQUE(event_id, faculty_id)
);

INSERT INTO students (name, email, branch, year, phone) VALUES
('Ananya Roy', 'ananya.roy@college.edu', 'CSE', 2, '9876543210'),
('Rohit Sharma', 'rohit.sharma@college.edu', 'ECE', 3, '9876543211'),
('Sneha Kapoor', 'sneha.kapoor@college.edu', 'IT', 1, '9876543212'),
('Vikram Singh', 'vikram.singh@college.edu', 'ME', 4, '9876543213'),
('Tanya Jain', 'tanya.jain@college.edu', 'CSE', 3, '9876543214');

INSERT INTO faculty (name, department, email) VALUES
('Dr. Nidhi Sharma', 'CSE', 'nidhi.sharma@college.edu'),
('Dr. Suresh Mehta', 'ECE', 'suresh.mehta@college.edu'),
('Prof. Reena Das', 'IT', 'reena.das@college.edu'),
('Dr. Kunal Bose', 'ME', 'kunal.bose@college.edu');

INSERT INTO events (event_name, event_date, location, seat_limit, available_seats) VALUES
('AI & ML Workshop', '2025-06-05', 'Auditorium A', 100, 100),
('Robotics Hackathon', '2025-06-08', 'Innovation Lab', 50, 50),
('Tech Quiz', '2025-06-10', 'Room 301', 30, 30),
('Web Dev Bootcamp', '2025-06-12', 'Lab 2', 60, 60);

INSERT INTO event_coordinators (event_id, faculty_id) VALUES
(1, 1),  -- AI & ML Workshop coordinated by Dr. Nidhi Sharma
(2, 2),  -- Robotics Hackathon by Dr. Suresh Mehta
(3, 3),  -- Tech Quiz by Prof. Reena Das
(4, 1),  -- Web Dev Bootcamp also coordinated by Dr. Nidhi Sharma
(4, 3);  -- And also by Prof. Reena Das


DELIMITER $$

CREATE TRIGGER after_registration_insert
AFTER INSERT ON registrations
FOR EACH ROW
BEGIN
  UPDATE events
  SET available_seats = available_seats - 1
  WHERE event_id = NEW.event_id;
END $$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE RegisterStudentForEvent(
  IN p_student_id INT,
  IN p_event_id INT
)
BEGIN
  DECLARE seats_left INT;

  SELECT available_seats INTO seats_left FROM events WHERE event_id = p_event_id;

  IF seats_left > 0 THEN
    INSERT INTO registrations(student_id, event_id)
    VALUES (p_student_id, p_event_id);
  ELSE
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No available seats for this event';
  END IF;
END $$

DELIMITER ;


CREATE VIEW student_event_view AS
SELECT 
    s.name AS student_name,
    e.event_name,
    e.event_date,
    r.reg_date
FROM 
    students s
JOIN 
    registrations r ON s.student_id = r.student_id
JOIN 
    events e ON r.event_id = e.event_id;
    
CALL RegisterStudentForEvent(1, 1); -- Ananya for AI Workshop
CALL RegisterStudentForEvent(2, 2); -- Rohit for Robotics Hackathon
CALL RegisterStudentForEvent(3, 3); -- Sneha for Tech Quiz
CALL RegisterStudentForEvent(4, 1); -- Vikram for AI Workshop
CALL RegisterStudentForEvent(5, 4); -- Tanya for Web Dev Bootcamp



SELECT event_name, event_date, available_seats
FROM events
WHERE available_seats > 0;


SELECT s.name, s.branch, s.year
FROM students s
JOIN registrations r ON s.student_id = r.student_id
WHERE r.event_id = 1;

CALL RegisterStudentForEvent(1, 2);

SELECT event_name, event_date, location
FROM events
WHERE event_date > '2025-06-07'
ORDER BY event_date ASC;

SELECT s.name AS student_name, s.branch, s.year
FROM students s
JOIN registrations r ON s.student_id = r.student_id
JOIN events e ON r.event_id = e.event_id
WHERE e.event_name = 'AI & ML Workshop';

SELECT e.event_name, COUNT(r.reg_id) AS total_registrations
FROM events e
LEFT JOIN registrations r ON e.event_id = r.event_id
GROUP BY e.event_id;

SELECT * FROM student_event_view;
