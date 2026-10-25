-- Rajarata University of Sri Lanka
-- Faculty of Applied Sciences
-- Department of Computing
-- Group Project - Binary Brains
-- Semester Management Database 

-- create database
drop database rjt_as_sm_db;
create database rjt_as_sm_db;
use rjt_as_sm_db;

-- degree program
create table degree_program (
    degree_code varchar(20) primary key,
    degree_name varchar(120) not null,
    degree_type enum('general', 'honours') not null default 'honours',
    duration_years enum ('3','4') not null
) engine innodb;

-- semester
create table semester (
    semester_id varchar(20) primary key,
    degree_code varchar(20) not null,
    academic_year varchar(15) not null,
    semester_name varchar(50) not null,
    start_date date not null,
    end_date date not null,
    foreign key (degree_code) references degree_program(degree_code) on update cascade on delete restrict,
    check (end_date > start_date),
    unique (degree_code, academic_year, semester_name)
) engine innodb;

-- lecturer superclass and subclasses
create table lecturer (
    lecturer_id varchar(20) primary key,
    full_name varchar(150) not null,
    preferred_day enum ('monday', 'tuesday', 'thursday', 'friday') null,
    preferred_time varchar(50) null,
    is_pref_approved_by_hod boolean not null default false,
    lecturer_type enum ('internal', 'visiting') not null,
    is_active boolean not null default true
) engine innodb;

create table internal_lecturer (
    lecturer_id varchar(20) primary key,
    designation varchar(80) not null,
    office_room varchar(30) null,
    foreign key (lecturer_id) references lecturer (lecturer_id) on update cascade on delete cascade
) engine innodb;

create table visiting_lecturer (
    lecturer_id varchar(20) primary key,
    email varchar(50) not null unique,
    phone varchar(15) not null,
    home_address text null,
    main_workplace varchar(150) null,
    can_conduct_online boolean not null default true,
    foreign key (lecturer_id) references lecturer (lecturer_id) on update cascade on delete cascade
) engine innodb;

-- course
create table course (
    course_code varchar(20) primary key,
    course_title varchar(150) not null,
    degree_stream enum('it', 'cs') not null,
    credits int not null,
    ca_marks int not null default 40 check (ca_marks in (30, 40)),
    final_marks int not null default 60 check (final_marks in (60, 70)),
    semester_id varchar(20) not null,
    lecturer_id varchar(20) not null,
    foreign key (semester_id) references semester(semester_id) on update cascade on delete restrict,
    foreign key (lecturer_id) references lecturer (lecturer_id) on update cascade on delete restrict,
    check ((ca_marks + final_marks) = 100)
) engine innodb;

-- lecture halls
create table lecture_hall (
    hall_no varchar(20) primary key,
    hall_name varchar(100) not null,
    capacity int not null check (capacity > 0),
    check (hall_no in ('L8', 'L11', 'auditorium hall'))
) engine innodb;

-- laboratories
create table laboratory (
    lab_no varchar(20) primary key,
    lab_name varchar(100) not null,
    capacity int not null check (capacity > 0),
    designated_stream enum('it', 'cs') not null
) engine innodb;

-- demonstrator
create table demonstrator (
    demo_id varchar(20) primary key,
    full_name varchar(150) not null,
    email varchar(120) not null unique,
    phone varchar(20) not null
) engine innodb;

-- practical session
create table practical_session (
    course_code varchar(20) not null,
    session_no varchar(20) not null,
    session_title varchar(120) not null,
    lab_no varchar(20) not null,
    demo_id varchar(20) not null,
    session_day enum('monday', 'tuesday','wednesday','thursday', 'friday') not null ,
    start_time time not null,
    end_time time not null,
    primary key (course_code, session_no),
    foreign key (course_code) references course (course_code) on update cascade on delete cascade,
    foreign key (lab_no) references laboratory(lab_no) on update cascade on delete restrict,
    foreign key (demo_id) references demonstrator(demo_id) on update cascade on delete restrict,
    check (end_time > start_time)
) engine innodb;

-- combined session
create table combined_session (
    combined_session_id varchar(20) primary key,
    session_name varchar(150) not null,
    hall_no varchar(20) not null,
    lecturer_id varchar(20) not null,
    day_of_week enum('monday', 'tuesday', 'thursday', 'friday') not null,
    start_time time not null,
    end_time time not null,
    duration_hours decimal (3,1) not null default 2.0,
    is_online boolean not null default true,
    foreign key (hall_no) references lecture_hall(hall_no) on update cascade on delete restrict,
    foreign key (lecturer_id) references lecturer (lecturer_id) on update cascade on delete restrict,
    check (end_time > start_time)
) engine innodb;

create table combined_session_course (
    combined_session_id varchar(20) not null,
    course_code varchar(20) not null,
    primary key (combined_session_id, course_code),
    foreign key (combined_session_id) references combined_session(combined_session_id) on update cascade on delete cascade,
    foreign key (course_code) references course (course_code) on update cascade on delete cascade
) engine innodb;

-- timetable and timetable_entry
create table timetable (
    timetable_id varchar(20) primary key,
    semester_id varchar(20) not null,
    academic_year varchar(15) not null,
    revision_iteration int not null default 1 check (revision_iteration between 1 and 10),
    status enum('draft', 'in_revision', 'approved', 'published') not null default 'draft',
    published_date date null,
    foreign key (semester_id) references semester (semester_id) on update cascade on delete restrict
) engine innodb;

create table timetable_entry (
    entry_id varchar(20) primary key,
    timetable_id varchar(20) not null,
    course_code varchar(20) not null,
    hall_no varchar(20) not null,
    session_day enum('monday', 'tuesday', 'wednesday', 'thursday', 'friday') not null,
    start_time time not null,
    end_time time not null,
    is_online boolean not null default false,
    foreign key (timetable_id) references timetable(timetable_id) on update cascade on delete cascade,
    foreign key (course_code) references course (course_code) on update cascade on delete cascade,
    foreign key (hall_no) references lecture_hall (hall_no) on update cascade on delete restrict,
    check (end_time > start_time),
    check (session_day <> 'wednesday')
) engine innodb;

-- student and online attendance
create table student (
    student_reg_no varchar(25) primary key,
    full_name varchar(150) not null,
    degree_stream enum('it', 'cs') not null,
    year varchar (10) not null
) engine innodb;

create table online_attendance (
    attendance_id varchar(20) primary key,
    student_reg_no varchar(25) not null,
    course_code varchar(20) not null,
    session_date date not null,
    duration_minutes int not null check (duration_minutes >= 0),
    is_attended boolean generated always as (duration_minutes >= 40) stored,
    foreign key (student_reg_no) references student (student_reg_no) on update cascade on delete cascade,
    foreign key (course_code) references course(course_code) on update cascade on delete cascade
) engine innodb;

-- indexes
create unique index idx_hall_clash_prevention on timetable_entry (hall_no, session_day, start_time, end_time);
create index idx_practical_wednesday on practical_session (lab_no, session_day, start_time);

-- Security of database
--  Create Roles
create role if not exists role_dean;
create role if not exists role_ar_officer;
create role if not exists role_hod;
create role if not exists role_clerk;

--  Grant Permissions to Roles
grant select on rjt_as_sm_db.* to role_dean;

grant select on rjt_as_sm_db.* to role_ar_officer;
grant insert, update on rjt_as_sm_db.timetable to role_ar_officer;
grant insert, update on rjt_as_sm_db.timetable_entry to role_ar_officer;

grant select, insert, update, delete on rjt_as_sm_db.* to role_hod;

grant select, insert, update, delete on rjt_as_sm_db.student to role_clerk;
grant select, insert, update, delete on rjt_as_sm_db.lecturer to role_clerk;
grant select, insert, update, delete on rjt_as_sm_db.course to role_clerk;

-- Create Users with Passwords
create user if not exists 'dean_fas'@'localhost' identified by 'dean123!';
create user if not exists 'hod_comp'@'localhost' identified by 'hod123!';
create user if not exists 'ar_office'@'localhost' identified by 'ar123!';
create user if not exists 'clerk_comp'@'localhost' identified by 'clerk123!';

-- Assign Roles to Users
grant role_dean to 'dean_fas'@'localhost';
grant role_hod to 'hod_comp'@'localhost';
grant role_ar_officer to 'ar_office'@'localhost';
grant role_clerk to 'clerk_comp'@'localhost';

-- Activate Default Roles for Users
set default role all to 'dean_fas'@'localhost';
set default role all to 'hod_comp'@'localhost';
set default role all to 'ar_office'@'localhost';
set default role all to 'clerk_comp'@'localhost';

flush privileges;

use rjt_as_sm_db;

-- add data Degree Program
insert into degree_program (degree_code, degree_name, degree_type, duration_years) values
('BSc_CS', 'BSc in Computer Science', 'honours', '4'),
('BSc_IT', 'BSc in Information Technology', 'general', '3');

-- add data Semester
insert into semester (semester_id, degree_code, academic_year, semester_name, start_date, end_date) values
('SEM_1', 'BSc_CS', '2025/2026', 'Semester 1', '2026-01-01', '2026-06-30'),
('SEM_2', 'BSc_IT', '2025/2026', 'Semester 1', '2026-01-01', '2026-06-30');

-- add data Lecturer
insert into lecturer (lecturer_id, full_name, preferred_day, preferred_time, is_pref_approved_by_hod, lecturer_type, is_active) values
('LEC_01', 'Dr. Suneth Perera', 'monday', '08:00 - 10:00', true, 'internal', true),
('LEC_02', 'Prof. Nimal Silva', 'tuesday', '10:00 - 12:00', true, 'visiting', true);

-- 4.add data Internal and Visiting Lecturer
insert into internal_lecturer (lecturer_id, designation, office_room) values
('LEC_01', 'Senior Lecturer', 'Room 102');

insert into visiting_lecturer (lecturer_id, email, phone, home_address, main_workplace, can_conduct_online) values
('LEC_02', 'nimal.silva@gmail.com', '0771234567', 'Colombo 07', 'University of Colombo', true);

-- add data Course
insert into course (course_code, course_title, degree_stream, credits, ca_marks, final_marks, semester_id, lecturer_id) values
('COM1101', 'Programming Concepts', 'cs', 3, 40, 60, 'SEM_1', 'LEC_01'),
('ICT1102', 'Database Systems', 'it', 3, 30, 70, 'SEM_2', 'LEC_02');

-- add data Lecture Hall
insert into lecture_hall (hall_no, hall_name, capacity) values
('L8', 'Main Lecture Hall 8', 120),
('L11', 'Lecture Hall 11', 80);

-- add data Laboratory
insert into laboratory (lab_no, lab_name, capacity, designated_stream) values
('LAB_A', 'Computing Lab A', 50, 'cs'),
('LAB_B', 'IT Software Lab', 40, 'it');

-- add data Demonstrator
insert into demonstrator (demo_id, full_name, email, phone) values
('DEMO_01', 'Kasun Jayasinghe', 'kasun@gmail.com', '0719876543'),
('DEMO_02', 'Dilini Fernando', 'dilini@gmail.com', '0751239874');

-- add data Practical Session
insert into practical_session (course_code, session_no, session_title, lab_no, demo_id, session_day, start_time, end_time) values
('COM1101', 'PS_01', 'C++ Basics Lab', 'LAB_A', 'DEMO_01', 'wednesday', '08:00:00', '10:00:00');

-- add data Combined Session
insert into combined_session (combined_session_id, session_name, hall_no, lecturer_id, day_of_week, start_time, end_time, duration_hours, is_online) values
('CSB_01', 'Joint Intro Lecture', 'L8', 'LEC_01', 'monday', '08:00:00', '10:00:00', 2.0, false);

insert into combined_session_course (combined_session_id, course_code) values
('CSB_01', 'COM1101');

-- add data Timetable
insert into timetable (timetable_id, semester_id, academic_year, revision_iteration, status, published_date) values
('TT_01', 'SEM_1', '2025/2026', 1, 'published', '2026-01-02');

-- add data timetable-entry
insert into timetable_entry (entry_id, timetable_id, course_code, hall_no, session_day, start_time, end_time, is_online) values
('TE_01', 'TT_01', 'COM1101', 'L8', 'monday', '08:00:00', '10:00:00', false);

-- add data Student
insert into student (student_reg_no, full_name, degree_stream, year) values
('ICT/20/001', 'Kamal Perera', 'it', '1st Year'),
('COM/20/002', 'Ruwan Silva', 'cs', '1st Year');

-- add data online_attendene
insert into online_attendance (attendance_id, student_reg_no, course_code, session_date, duration_minutes) values
('ATT_01', 'ICT/20/001', 'ICT1102', '2026-02-10', 45),
('ATT_02', 'COM/20/002', 'COM1101', '2026-02-10', 30);