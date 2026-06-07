-- ============================================================
--   أكاديمية البعد الجديد  —  قاعدة البيانات الكاملة
--   Academy Al-Bu'd Al-Jadeed  —  Full Database Schema
--   MySQL / MariaDB  •  UTF-8 (Arabic support)
-- ============================================================
 
SET NAMES 'utf8mb4';
SET CHARACTER SET utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
 
-- ============================================================
-- 1. إنشاء قاعدة البيانات
-- ============================================================
CREATE DATABASE IF NOT EXISTS `academy_db`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
 
USE `academy_db`;
 
-- ============================================================
-- 2. جدول المستخدمين  (users)
-- ============================================================
CREATE TABLE IF NOT EXISTS `users` (
  `id`         BIGINT       UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`       VARCHAR(120) NOT NULL,
  `email`      VARCHAR(180) NOT NULL UNIQUE,
  `password`   VARCHAR(255) NOT NULL COMMENT 'bcrypt hash',
  `role`       ENUM('admin','teacher','student') NOT NULL DEFAULT 'student',
  `status`     ENUM('active','banned')           NOT NULL DEFAULT 'active',
  `avatar`     VARCHAR(10)  DEFAULT NULL COMMENT 'first letter of name',
  `joined`     DATE         NOT NULL DEFAULT (CURDATE()),
  `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_users_role`   (`role`),
  INDEX `idx_users_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
 
-- ============================================================
-- 3. جدول الدورات  (courses)
-- ============================================================
CREATE TABLE IF NOT EXISTS `courses` (
  `id`          BIGINT       UNSIGNED NOT NULL AUTO_INCREMENT,
  `title`       VARCHAR(200) NOT NULL,
  `icon`        VARCHAR(20)  DEFAULT '📖',
  `category`    VARCHAR(80)  NOT NULL DEFAULT 'عام',
  `units`       SMALLINT     UNSIGNED NOT NULL DEFAULT 1,
  `price`       DECIMAL(8,2) NOT NULL DEFAULT 0.00 COMMENT '0 = free',
  `status`      ENUM('published','draft','archived') NOT NULL DEFAULT 'published',
  `students`    INT          UNSIGNED NOT NULL DEFAULT 0 COMMENT 'cached enrolment count',
  `teacher_id`  BIGINT       UNSIGNED DEFAULT NULL,
  `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_courses_status`   (`status`),
  INDEX `idx_courses_category` (`category`),
  CONSTRAINT `fk_courses_teacher`
    FOREIGN KEY (`teacher_id`) REFERENCES `users` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
 
-- ============================================================
-- 4. جدول الفيديوهات  (videos)
-- ============================================================
CREATE TABLE IF NOT EXISTS `videos` (
  `id`          BIGINT       UNSIGNED NOT NULL AUTO_INCREMENT,
  `course_id`   BIGINT       UNSIGNED NOT NULL,
  `title`       VARCHAR(200) NOT NULL,
  `youtube_id`  VARCHAR(20)  DEFAULT NULL COMMENT 'YouTube video ID (11 chars)',
  `duration`    VARCHAR(40)  DEFAULT NULL COMMENT 'e.g. "15 دقيقة"',
  `sort_order`  SMALLINT     UNSIGNED NOT NULL DEFAULT 0,
  `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_videos_course`  (`course_id`),
  INDEX `idx_videos_order`   (`course_id`, `sort_order`),
  CONSTRAINT `fk_videos_course`
    FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
 
-- ============================================================
-- 5. جدول ملفات الامتحانات (quiz_files)
--    لكل فيديو يمكن رفع PDF أو صورة بدلاً من أسئلة نصية
-- ============================================================
CREATE TABLE IF NOT EXISTS `quiz_files` (
  `id`          BIGINT       UNSIGNED NOT NULL AUTO_INCREMENT,
  `video_id`    BIGINT       UNSIGNED NOT NULL UNIQUE,
  `file_name`   VARCHAR(255) NOT NULL,
  `file_type`   VARCHAR(80)  NOT NULL COMMENT 'MIME type e.g. application/pdf',
  `file_data`   LONGTEXT     NOT NULL COMMENT 'Base64-encoded file content',
  `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_qf_video`
    FOREIGN KEY (`video_id`) REFERENCES `videos` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
 
-- ============================================================
-- 6. جدول الأسئلة النصية في الامتحانات  (quiz_questions)
-- ============================================================
CREATE TABLE IF NOT EXISTS `quiz_questions` (
  `id`          BIGINT       UNSIGNED NOT NULL AUTO_INCREMENT,
  `video_id`    BIGINT       UNSIGNED NOT NULL,
  `question`    TEXT         NOT NULL,
  `answer_index` TINYINT     UNSIGNED NOT NULL DEFAULT 0 COMMENT 'index of correct option (0-based)',
  `sort_order`  SMALLINT     UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  INDEX `idx_qq_video` (`video_id`),
  CONSTRAINT `fk_qq_video`
    FOREIGN KEY (`video_id`) REFERENCES `videos` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
 
-- ============================================================
-- 7. جدول خيارات الأسئلة  (quiz_options)
-- ============================================================
CREATE TABLE IF NOT EXISTS `quiz_options` (
  `id`          BIGINT       UNSIGNED NOT NULL AUTO_INCREMENT,
  `question_id` BIGINT       UNSIGNED NOT NULL,
  `option_text` VARCHAR(500) NOT NULL,
  `option_index` TINYINT     UNSIGNED NOT NULL DEFAULT 0 COMMENT '0=A, 1=B, 2=C, 3=D',
  PRIMARY KEY (`id`),
  INDEX `idx_qo_question` (`question_id`),
  CONSTRAINT `fk_qo_question`
    FOREIGN KEY (`question_id`) REFERENCES `quiz_questions` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
 
-- ============================================================
-- 8. جدول التسجيل في الدورات  (enrollments)
-- ============================================================
CREATE TABLE IF NOT EXISTS `enrollments` (
  `id`          BIGINT       UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`     BIGINT       UNSIGNED NOT NULL,
  `course_id`   BIGINT       UNSIGNED NOT NULL,
  `enrolled_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `progress`    TINYINT      UNSIGNED NOT NULL DEFAULT 0 COMMENT 'percentage 0-100',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_enrollment` (`user_id`, `course_id`),
  INDEX `idx_enr_course` (`course_id`),
  CONSTRAINT `fk_enr_user`
    FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_enr_course`
    FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
 
-- ============================================================
-- 9. جدول نتائج الامتحانات  (quiz_results)
-- ============================================================
CREATE TABLE IF NOT EXISTS `quiz_results` (
  `id`          BIGINT       UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`     BIGINT       UNSIGNED NOT NULL,
  `video_id`    BIGINT       UNSIGNED NOT NULL,
  `score`       TINYINT      UNSIGNED NOT NULL DEFAULT 0 COMMENT 'number of correct answers',
  `total`       TINYINT      UNSIGNED NOT NULL DEFAULT 0,
  `taken_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_qr_user`  (`user_id`),
  INDEX `idx_qr_video` (`video_id`),
  CONSTRAINT `fk_qr_user`
    FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_qr_video`
    FOREIGN KEY (`video_id`) REFERENCES `videos` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
 
-- ============================================================
-- 10. جدول التقييمات  (reviews)
-- ============================================================
CREATE TABLE IF NOT EXISTS `reviews` (
  `id`          BIGINT       UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`     BIGINT       UNSIGNED NOT NULL,
  `course_id`   BIGINT       UNSIGNED NOT NULL,
  `rating`      TINYINT      UNSIGNED NOT NULL DEFAULT 5 CHECK (`rating` BETWEEN 1 AND 5),
  `review_text` TEXT         DEFAULT NULL,
  `status`      ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_review` (`user_id`, `course_id`),
  INDEX `idx_reviews_course`  (`course_id`),
  INDEX `idx_reviews_status`  (`status`),
  CONSTRAINT `fk_rev_user`
    FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_rev_course`
    FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
 
-- ============================================================
-- 11. جدول إعدادات الموقع  (site_settings)
-- ============================================================
CREATE TABLE IF NOT EXISTS `site_settings` (
  `setting_key`   VARCHAR(80)  NOT NULL,
  `setting_value` TEXT         DEFAULT NULL,
  `updated_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
 
-- ============================================================
-- 12. البيانات الافتراضية  (Seed Data)
-- ============================================================
 
-- المستخدمون
INSERT INTO `users` (`id`,`name`,`email`,`password`,`role`,`status`,`avatar`,`joined`) VALUES
(1, 'المدير العام',  'sj4380004@gmail.com',     '$2b$12$PLACEHOLDER_ADMIN_HASH',   'admin',   'active', 'م', '2024-01-01'),
(2, 'أحمد محمد',    'ahmed@student.com',         '$2b$12$PLACEHOLDER_STUDENT_HASH', 'student', 'active', 'أ', '2024-03-15'),
(3, 'سارة علي',     'sara@student.com',          '$2b$12$PLACEHOLDER_STUDENT_HASH', 'student', 'active', 'س', '2024-04-10'),
(4, 'محمد خالد',    'm.khalid@teacher.com',      '$2b$12$PLACEHOLDER_TEACHER_HASH', 'teacher', 'active', 'م', '2024-02-01'),
(5, 'فاطمة حسن',   'fatima@student.com',         '$2b$12$PLACEHOLDER_STUDENT_HASH', 'student', 'banned', 'ف', '2024-05-01');
-- ملاحظة: استبدل PLACEHOLDER_*_HASH بـ bcrypt hash حقيقية عند النشر
 
-- الدورات
INSERT INTO `courses` (`id`,`title`,`icon`,`category`,`units`,`price`,`status`,`students`,`teacher_id`) VALUES
(1, 'التكامل',         '∫',     'الرياضيات', 2, 0.00, 'published', 45, 4),
(2, 'التفاضل',         'دص/دس', 'الرياضيات', 2, 0.00, 'published', 38, 4),
(3, 'الميكانيكا',      '⚙️',    'الفيزياء',  3, 0.00, 'published', 52, 4),
(4, 'الكهرباء',        '⚡',    'الفيزياء',  2, 0.00, 'published', 29, 4),
(5, 'الكهرومغناطيسية', '🧲',   'الفيزياء',  3, 0.00, 'published', 33, 4);
 
-- فيديوهات الدورة 1: التكامل
INSERT INTO `videos` (`id`,`course_id`,`title`,`youtube_id`,`duration`,`sort_order`) VALUES
(1, 1, 'مقدمة في التكامل',  'rfG8ce4nNh0', '15 دقيقة', 0),
(2, 1, 'التكامل المحدود',   'rfG8ce4nNh0', '20 دقيقة', 1),
(3, 1, 'تطبيقات التكامل',  'rfG8ce4nNh0', '18 دقيقة', 2);
 
-- فيديوهات الدورة 2: التفاضل
INSERT INTO `videos` (`id`,`course_id`,`title`,`youtube_id`,`duration`,`sort_order`) VALUES
(4, 2, 'مفهوم المشتقة',  'rfG8ce4nNh0', '14 دقيقة', 0),
(5, 2, 'قواعد التفاضل', 'rfG8ce4nNh0', '22 دقيقة', 1);
 
-- فيديوهات الدورة 3: الميكانيكا
INSERT INTO `videos` (`id`,`course_id`,`title`,`youtube_id`,`duration`,`sort_order`) VALUES
(6, 3, 'قوانين نيوتن',    'rfG8ce4nNh0', '16 دقيقة', 0),
(7, 3, 'الحركة المنتظمة', 'rfG8ce4nNh0', '12 دقيقة', 1);
 
-- فيديوهات الدورة 4: الكهرباء
INSERT INTO `videos` (`id`,`course_id`,`title`,`youtube_id`,`duration`,`sort_order`) VALUES
(8, 4, 'الشحنة الكهربائية', 'rfG8ce4nNh0', '13 دقيقة', 0),
(9, 4, 'قانون أوم',         'rfG8ce4nNh0', '17 دقيقة', 1);
 
-- فيديوهات الدورة 5: الكهرومغناطيسية
INSERT INTO `videos` (`id`,`course_id`,`title`,`youtube_id`,`duration`,`sort_order`) VALUES
(10, 5, 'المجال المغناطيسي',     'rfG8ce4nNh0', '15 دقيقة', 0),
(11, 5, 'الحث الكهرومغناطيسي', 'rfG8ce4nNh0', '19 دقيقة', 1);
 
-- أسئلة الامتحانات -----------------------------------------------
 
-- فيديو 1: مقدمة في التكامل
INSERT INTO `quiz_questions` (`id`,`video_id`,`question`,`answer_index`,`sort_order`) VALUES
(1, 1, 'ما هو التكامل؟',   1, 0),
(2, 1, 'ما رمز التكامل؟',  2, 1);
 
INSERT INTO `quiz_options` (`question_id`,`option_text`,`option_index`) VALUES
(1, 'عملية جمع',            0),
(1, 'عملية إيجاد المساحة',  1),
(1, 'عملية ضرب',            2),
(1, 'عملية طرح',            3),
(2, '∂',  0),
(2, '∑',  1),
(2, '∫',  2),
(2, 'Δ',  3);
 
-- فيديو 2: التكامل المحدود
INSERT INTO `quiz_questions` (`id`,`video_id`,`question`,`answer_index`,`sort_order`) VALUES
(3, 2, 'التكامل المحدود يحسب؟', 1, 0);
 
INSERT INTO `quiz_options` (`question_id`,`option_text`,`option_index`) VALUES
(3, 'المشتقة',                           0),
(3, 'المساحة بين المنحنى والمحور',       1),
(3, 'الحد',                              2),
(3, 'التفاضل',                           3);
 
-- فيديو 3: تطبيقات التكامل
INSERT INTO `quiz_questions` (`id`,`video_id`,`question`,`answer_index`,`sort_order`) VALUES
(4, 3, 'أين نستخدم التكامل في الحياة؟', 1, 0);
 
INSERT INTO `quiz_options` (`question_id`,`option_text`,`option_index`) VALUES
(4, 'الطب فقط',              0),
(4, 'الهندسة والفيزياء',     1),
(4, 'الأدب',                 2),
(4, 'التاريخ',               3);
 
-- فيديو 4: مفهوم المشتقة
INSERT INTO `quiz_questions` (`id`,`video_id`,`question`,`answer_index`,`sort_order`) VALUES
(5, 4, 'المشتقة تعبّر عن؟', 1, 0);
 
INSERT INTO `quiz_options` (`question_id`,`option_text`,`option_index`) VALUES
(5, 'المساحة',       0),
(5, 'معدل التغيير',  1),
(5, 'الحجم',         2),
(5, 'الكتلة',        3);
 
-- فيديو 6: قوانين نيوتن
INSERT INTO `quiz_questions` (`id`,`video_id`,`question`,`answer_index`,`sort_order`) VALUES
(6, 6, 'القانون الأول لنيوتن يتعلق بـ؟', 1, 0);
 
INSERT INTO `quiz_options` (`question_id`,`option_text`,`option_index`) VALUES
(6, 'القوة والتسارع',       0),
(6, 'القصور الذاتي',        1),
(6, 'الفعل ورد الفعل',      2),
(6, 'الطاقة',               3);
 
-- فيديو 9: قانون أوم
INSERT INTO `quiz_questions` (`id`,`video_id`,`question`,`answer_index`,`sort_order`) VALUES
(7, 9, 'قانون أوم يربط بين؟', 1, 0);
 
INSERT INTO `quiz_options` (`question_id`,`option_text`,`option_index`) VALUES
(7, 'الكتلة والتسارع',         0),
(7, 'الجهد والتيار والمقاومة', 1),
(7, 'الطاقة والشغل',           2),
(7, 'الضغط والحجم',            3);
 
-- التقييمات
INSERT INTO `reviews` (`id`,`user_id`,`course_id`,`rating`,`review_text`,`status`,`created_at`) VALUES
(1, 2, 1, 5, 'شرح رائع ومفهوم جداً',   'approved', '2026-05-01 00:00:00'),
(2, 3, 3, 4, 'محتوى ممتاز وشامل',       'pending',  '2026-05-10 00:00:00');
 
-- إعدادات الموقع
INSERT INTO `site_settings` (`setting_key`, `setting_value`) VALUES
('siteName',          'أكاديمية البعد الجديد'),
('siteEmail',         'sj4380004@gmail.com'),
('sitePhone',         '+970595194601'),
('siteLocation',      'الخليل - فلسطين'),
('maintenanceMode',   'false'),
('allowRegistration', 'true');
 
SET FOREIGN_KEY_CHECKS = 1;
 
-- ============================================================
-- 13. طلبات مفيدة للإدارة  (Useful Admin Queries)
-- ============================================================
 
-- عرض كل الدورات مع عدد فيديوهاتها وأسئلتها
/*
SELECT
  c.id,
  c.title,
  c.category,
  COUNT(DISTINCT v.id)  AS video_count,
  COUNT(DISTINCT qq.id) AS question_count
FROM courses c
LEFT JOIN videos v         ON v.course_id  = c.id
LEFT JOIN quiz_questions qq ON qq.video_id = v.id
GROUP BY c.id, c.title, c.category;
*/
 
-- عرض تقدم الطلاب في كل دورة
/*
SELECT
  u.name AS student,
  c.title AS course,
  e.progress,
  e.enrolled_at
FROM enrollments e
JOIN users   u ON u.id = e.user_id
JOIN courses c ON c.id = e.course_id
ORDER BY e.enrolled_at DESC;
*/
 
-- إحصائيات عامة
/*
SELECT
  (SELECT COUNT(*) FROM users   WHERE role='student' AND status='active') AS active_students,
  (SELECT COUNT(*) FROM courses WHERE status='published')                  AS published_courses,
  (SELECT COUNT(*) FROM videos)                                            AS total_videos,
  (SELECT COUNT(*) FROM quiz_questions)                                    AS total_questions,
  (SELECT COUNT(*) FROM reviews WHERE status='approved')                   AS approved_reviews;
*/
 
-- ============================================================
-- 14. جدول الروابط المفيدة  (useful_links)  ← جديد
-- ============================================================
CREATE TABLE IF NOT EXISTS `useful_links` (
  `id`          BIGINT       UNSIGNED NOT NULL AUTO_INCREMENT,
  `title`       VARCHAR(200) NOT NULL,
  `description` TEXT         DEFAULT NULL,
  `url`         VARCHAR(500) NOT NULL,
  `icon`        VARCHAR(20)  DEFAULT '🔗',
  `color`       VARCHAR(20)  DEFAULT '#6c47ff',
  `sort_order`  SMALLINT     UNSIGNED NOT NULL DEFAULT 0,
  `is_active`   TINYINT(1)   NOT NULL DEFAULT 1,
  `created_by`  BIGINT       UNSIGNED DEFAULT NULL,
  `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_links_order` (`sort_order`),
  CONSTRAINT `fk_links_creator`
    FOREIGN KEY (`created_by`) REFERENCES `users` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
 
INSERT INTO `useful_links` (`title`,`description`,`url`,`icon`,`color`,`sort_order`) VALUES
('ديسموس',             'آلة حاسبة بيانية مجانية عبر الإنترنت',              'https://www.desmos.com/calculator',                                                          '📊','#e9425e',1),
('ولفرام ألفا',        'محرك حساب ذكي لحل المسائل الرياضية',               'https://www.wolframalpha.com',                                                               '🧮','#dd1100',2),
('خان أكاديمي',        'منصة تعليمية مجانية في الرياضيات والعلوم',          'https://ar.khanacademy.org',                                                                 '🎓','#14bf96',3),
('ويكيبيديا - رياضيات','مرجع شامل للمفاهيم الرياضية',                       'https://ar.wikipedia.org/wiki/%D8%B1%D9%8A%D8%A7%D8%B6%D9%8A%D8%A7%D8%AA',               '📖','#3366cc',4),
('GeoGebra',            'أداة رسم هندسي وحاسبة جبرية تفاعلية',              'https://www.geogebra.org',                                                                   '📐','#7744aa',5),
('3Blue1Brown',         'قناة يوتيوب تشرح الرياضيات بصرياً بأسلوب مميز',    'https://www.youtube.com/@3blue1brown',                                                       '🔵','#1a237e',6),
('MIT OpenCourseWare',  'دورات أكاديمية مجانية من معهد MIT',                 'https://ocw.mit.edu',                                                                        '🏛️','#8b0000',7),
('Paul Math Notes',     'ملاحظات رياضية للجبر وحساب التفاضل',               'https://tutorial.math.lamar.edu',                                                            '📝','#2e7d32',8);
 
-- ============================================================
-- 15. جدول سجل تعديلات الموقع  (site_changes_log)  ← جديد
--     يحفظ كل تعديل يجريه المدير ويُستخدم للـ sync
-- ============================================================
CREATE TABLE IF NOT EXISTS `site_changes_log` (
  `id`           BIGINT       UNSIGNED NOT NULL AUTO_INCREMENT,
  `change_type`  ENUM(
    'course_add','course_edit','course_delete',
    'video_add','video_edit','video_delete',
    'quiz_edit',
    'link_add','link_edit','link_delete',
    'user_add','user_edit','user_delete','user_ban',
    'setting_change','review_approve','review_delete'
  ) NOT NULL,
  `entity_id`    BIGINT       UNSIGNED DEFAULT NULL COMMENT 'affected row id',
  `entity_table` VARCHAR(50)  DEFAULT NULL COMMENT 'e.g. courses, videos, useful_links',
  `summary`      VARCHAR(500) DEFAULT NULL COMMENT 'human-readable description',
  `payload`      JSON         DEFAULT NULL COMMENT 'full change data for replay',
  `changed_by`   BIGINT       UNSIGNED DEFAULT NULL,
  `changed_at`   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_scl_type`    (`change_type`),
  INDEX `idx_scl_entity`  (`entity_table`, `entity_id`),
  INDEX `idx_scl_changed` (`changed_at`),
  CONSTRAINT `fk_scl_user`
    FOREIGN KEY (`changed_by`) REFERENCES `users` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
 
-- ============================================================
-- 16. جدول التسجيل الموسّع  (user_profiles)  ← جديد
--     معلومات إضافية لكل مستخدم عند التسجيل
-- ============================================================
CREATE TABLE IF NOT EXISTS `user_profiles` (
  `user_id`       BIGINT       UNSIGNED NOT NULL,
  `phone`         VARCHAR(30)  DEFAULT NULL,
  `bio`           TEXT         DEFAULT NULL,
  `grade`         VARCHAR(50)  DEFAULT NULL COMMENT 'e.g. الصف الحادي عشر',
  `country`       VARCHAR(80)  DEFAULT 'فلسطين',
  `city`          VARCHAR(80)  DEFAULT NULL,
  `profile_image` VARCHAR(255) DEFAULT NULL COMMENT 'URL or base64 path',
  `last_login`    TIMESTAMP    NULL DEFAULT NULL,
  `total_score`   INT          UNSIGNED NOT NULL DEFAULT 0 COMMENT 'cumulative quiz score',
  `created_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  CONSTRAINT `fk_up_user`
    FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
 
-- ============================================================
-- 17. جدول الإشعارات  (notifications)  ← جديد
-- ============================================================
CREATE TABLE IF NOT EXISTS `notifications` (
  `id`         BIGINT       UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`    BIGINT       UNSIGNED DEFAULT NULL COMMENT 'NULL = broadcast to all',
  `title`      VARCHAR(200) NOT NULL,
  `body`       TEXT         DEFAULT NULL,
  `type`       ENUM('info','success','warning','error') NOT NULL DEFAULT 'info',
  `is_read`    TINYINT(1)   NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_notif_user` (`user_id`),
  INDEX `idx_notif_read` (`is_read`),
  CONSTRAINT `fk_notif_user`
    FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
 
SET FOREIGN_KEY_CHECKS = 1;
 
