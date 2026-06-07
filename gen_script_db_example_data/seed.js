const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Khởi tạo kết nối với Firebase Firestore
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// ==========================================
// ĐỊNH NGHĨA 10 MẪU DỮ LIỆU GỐC (INTERCONNECTED DATA)
// ==========================================

// 1. Bộ dữ liệu Users (Bao gồm User thường, VIP, Expert và Admin)
const usersData = {
    "user_001": {
        "uid": "user_001",
        "email": "an.nguyen@gmail.com",
        "displayName": "Nguyễn Văn An",
        "avatarUrl": "https://i.pravatar.cc/150?img=11",
        "role": "user",
        "membership": "normal",
        "createdAt": new Date("2026-06-01T08:00:00Z")
    },
    "user_002": {
        "uid": "user_002",
        "email": "binh.le@gmail.com",
        "displayName": "Lê Thị Bình",
        "avatarUrl": "https://i.pravatar.cc/150?img=20",
        "role": "user",
        "membership": "vip",
        "createdAt": new Date("2026-06-02T09:30:00Z")
    },
    "expert_001": {
        "uid": "expert_001",
        "email": "dac.tran@agritech.vn",
        "displayName": "Chuyên gia Trần Đắc",
        "avatarUrl": "https://i.pravatar.cc/150?img=60",
        "role": "expert",
        "membership": "normal",
        "createdAt": new Date("2026-05-20T14:00:00Z"),
        "expertProfile": {
            "specialization": "Cây mọng nước, Sen đá, Bonsai mini",
            "bio": "Thạc sĩ Nông nghiệp - 5 năm kinh nghiệm nghiên cứu thực vật học đô thị.",
            "status": "approved"
        }
    },
    "admin_001": {
        "uid": "admin_001",
        "email": "hoang.pham@homeplant.com",
        "displayName": "Phạm Minh Hoàng",
        "avatarUrl": "https://i.pravatar.cc/150?img=33",
        "role": "admin",
        "membership": "normal",
        "createdAt": new Date("2026-05-01T00:00:00Z")
    }
};

// 2. Dữ liệu Cây trồng của từng User (Subcollection: user_plants)
const userPlantsData = {
    "user_001": [
        {
            "plantId": "u1_plant_01",
            "templateId": "PLANT_MASTER_999",
            "customName": "Lưỡi Hổ Phòng Ngủ",
            "imageUrl": "https://images.unsplash.com/photo-1599599810769-bcde5a160d32",
            "plantedAt": new Date("2026-06-01T10:00:00Z"),
            "status": "healthy",
            "createdAt": new Date("2026-06-01T10:00:00Z"),
            // Subcollection: care_history
            "care_history": [
                { "logId": "log_01", "type": "water", "notes": "Tưới ẩm nhẹ quanh gốc.", "createdAt": new Date("2026-06-01T10:05:00Z") },
                { "logId": "log_02", "type": "note", "notes": "Cây bắt đầu ra mầm nhỏ ở kẽ lá.", "createdAt": new Date("2026-06-05T07:00:00Z") }
            ],
            // Subcollection: schedules
            "schedules": [
                { "scheduleId": "sch_01", "type": "water", "frequencyDays": 7, "lastPerformed": new Date("2026-06-01T10:05:00Z"), "nextDue": new Date("2026-06-08T10:05:00Z") }
            ]
        }
    ],
    "user_002": [
        {
            "plantId": "u2_plant_01",
            "templateId": "PLANT_MASTER_888",
            "customName": "Bé Sen Đá Đô La",
            "imageUrl": "https://images.unsplash.com/photo-1509423352804-637f2f6e09a9",
            "plantedAt": new Date("2026-06-02T11:00:00Z"),
            "status": "sick",
            "createdAt": new Date("2026-06-02T11:00:00Z"),
            "care_history": [
                { "logId": "log_03", "type": "water", "notes": "Tưới đẫm nước ngập chậu.", "createdAt": new Date("2026-06-02T11:05:00Z") },
                { "logId": "log_04", "type": "fertilize", "notes": "Bón thêm một ít phân trùn quế viên nén.", "createdAt": new Date("2026-06-04T16:00:00Z") }
            ],
            "schedules": [
                { "scheduleId": "sch_02", "type": "water", "frequencyDays": 3, "lastPerformed": new Date("2026-06-05T07:00:00Z"), "nextDue": new Date("2026-06-08T07:00:00Z") },
                { "scheduleId": "sch_03", "type": "fertilize", "frequencyDays": 30, "lastPerformed": new Date("2026-06-04T16:00:00Z"), "nextDue": new Date("2026-07-04T16:00:00Z") }
            ]
        }
    ]
};

// 3. Collection: plant_templates (Thư viện cây mẫu)
const plantTemplatesData = [
    {
        "templateId": "PLANT_MASTER_999",
        "name": "Cây Lưỡi Hổ",
        "scientificName": "Sansevieria trifasciata",
        "description": "Loại cây lọc không khí cực tốt, chịu hạn giỏi và dễ chăm sóc trong nhà.",
        "imageUrl": "https://images.unsplash.com/photo-1599599810769-bcde5a160d32",
        "careInstructions": {
            "light": "Ánh sáng bán phần hoặc bóng râm",
            "water": "Tưới 1 lần/tuần, tránh úng nước",
            "soil": "Đất cát pha đất mùn, thoát nước cực nhanh"
        },
        "diseases": [
            { "name": "Thối rễ do úng", "symptoms": "Lá bị vàng mềm nhũn từ gốc lan dần lên.", "treatment": "Ngừng tưới ngay, dỡ chậu cắt rễ thối, thay đất khô mới." }
        ],
        "isFeatured": true,
        "createdAt": new Date("2026-05-01T00:00:00Z")
    },
    {
        "templateId": "PLANT_MASTER_888",
        "name": "Sen Đá Đô La",
        "scientificName": "Portulacaria afra",
        "description": "Thân mọng nước, lá tròn nhỏ giống đồng xu, mang ý nghĩa may mắn tài lộc.",
        "imageUrl": "https://images.unsplash.com/photo-1509423352804-637f2f6e09a9",
        "careInstructions": {
            "light": "Cần nhiều ánh sáng trực tiếp, ít nhất 4-6 tiếng nắng",
            "water": "Tưới khi đất khô hoàn toàn (khoảng 3-5 ngày/lần)",
            "soil": "Đất chuyên dụng cho sen đá đá perlite, xỉ than"
        },
        "diseases": [
            { "name": "Nấm phấn trắng", "symptoms": "Các đốm trắng như bột bám quanh bẹ lá.", "treatment": "Lau sạch bằng cồn pha loãng hoặc phun thuốc trị nấm hữu cơ." }
        ],
        "isFeatured": true,
        "createdAt": new Date("2026-05-01T00:00:00Z")
    }
];

// 4. Collection: articles (Cẩm nang kiến thức)
const articlesData = [
    {
        "articleId": "ART_001",
        "title": "Bí quyết cứu sống Sen Đá bị úng nước mùa mưa bão",
        "content": "## Nguyên nhân úng nước\nMùa mưa độ ẩm không khí tăng cao kèm theo thiếu nắng...\n## Các bước xử lý cấp tốc\n1. Nhổ cây ra khỏi chậu.\n2. Cắt bỏ rễ thối.\n3. Phơi khô rễ nơi thoáng mát 3 ngày...",
        "coverImage": "https://images.unsplash.com/photo-1512428559087-560fa5ceab42",
        "tags": ["sen đá", "mùa mưa", "cứu cây"],
        "views": 1420,
        "createdAt": new Date("2026-06-05T10:00:00Z")
    }
];

// 5. Collection: community_posts (Bài đăng MXH cộng đồng)
const communityPostsData = [
    {
        "postId": "POST_555",
        "authorId": "user_002",
        "authorName": "Lê Thị Bình",
        "authorAvatar": "https://i.pravatar.cc/150?img=20",
        "content": "Cây sen đá của em lá bị mềm nhũn và rụng lả tả khi chạm vào, có phải bị thối rễ rồi không ạ? Cứu em với!",
        "images": ["https://images.unsplash.com/photo-1604762524889-3e2fcc145613"],
        "likeCount": 12,
        "commentCount": 1,
        "likedBy": ["user_001"],
        "status": "approved",
        "createdAt": new Date("2026-06-07T14:30:00Z"),
        // Subcollection: comments
        "comments": [
            {
                "commentId": "CMT_991",
                "authorId": "expert_001",
                "authorName": "Chuyên gia Trần Đắc",
                "authorAvatar": "https://i.pravatar.cc/150?img=60",
                "content": "Đúng hiện tượng úng rồi bạn nhé. Bạn hãy làm theo hướng dẫn tại bài viết ART_001 trên hệ thống ngay lập tức nha!",
                "createdAt": new Date("2026-06-07T15:00:00Z")
            }
        ]
    }
];

// 6. Collection: ai_diagnoses (Lịch sử quét AI)
const aiDiagnosesData = [
    {
        "diagnosisId": "AI_001",
        "userId": "user_002",
        "uploadedImageUrl": "https://images.unsplash.com/photo-1604762524889-3e2fcc145613",
        "result": {
            "diseaseName": "Thối rễ do thừa nước",
            "confidence": 0.94,
            "cause": "Đất trồng giữ nước quá lâu và chậu không có lỗ thoát nước tốt.",
            "treatment": "Thay đất mục, cắt tỉa phần thối rễ, bôi vôi hoặc thuốc liền sẹo thực vật."
        },
        "createdAt": new Date("2026-06-07T14:15:00Z")
    }
];

// 7. Collection: qa_threads (Phòng chat tư vấn 1-1 chuyên gia)
const qaThreadsData = [
    {
        "threadId": "QA_001",
        "userId": "user_001",
        "userName": "Nguyễn Văn An",
        "userAvatar": "https://i.pravatar.cc/150?img=11",
        "expertId": "expert_001",
        "expertName": "Chuyên gia Trần Đắc",
        "title": "Cây lưỡi hổ bón loại phân gì để ra hoa?",
        "lastMessage": "Chào bạn, lưỡi hổ rất hiếm ra hoa, bạn cần bổ sung hàm lượng Kali và Phốt pho cao nhé.",
        "lastMessageAt": new Date("2026-06-07T16:20:00Z"),
        "status": "processing",
        "createdAt": new Date("2026-06-07T16:00:00Z"),
        // Subcollection: replies
        "replies": [
            {
                "replyId": "REP_001",
                "senderId": "user_001",
                "senderName": "Nguyễn Văn An",
                "senderRole": "user",
                "content": "Chào chuyên gia, cây lưỡi hổ nhà em nuôi 2 năm rồi tươi tốt nhưng chưa bao giờ ra hoa. Làm sao để kích thích hoa ạ?",
                "images": [],
                "createdAt": new Date("2026-06-07T16:00:00Z")
            },
            {
                "replyId": "REP_002",
                "senderId": "expert_001",
                "senderName": "Chuyên gia Trần Đắc",
                "senderRole": "expert",
                "content": "Chào bạn, lưỡi hổ rất hiếm ra hoa, bạn cần bổ sung hàm lượng Kali và Phốt pho cao nhé. Ngoài ra hãy cho cây đón nắng sớm buổi sáng khoảng 2-3 tiếng.",
                "images": [],
                "createdAt": new Date("2026-06-07T16:20:00Z")
            }
        ]
    }
];


// ==========================================
// HÀM THỰC THI SEED DATA VÀO FIRESTORE
// ==========================================
async function runSeeder() {
    try {
        console.log('🚀 Bắt đầu quá trình nạp dữ liệu mẫu cho HomePlant...');

        // 1. Sinh dữ liệu Users và Subcollections của User
        for (const [userId, userData] of Object.entries(usersData)) {
            const userRef = db.collection('users').doc(userId);
            await userRef.set(userData);
            console.log(`✔️  Đã tạo User: ${userData.displayName} (${userData.role})`);

            // Kiểm tra xem user này có cây mẫu để nạp không
            if (userPlantsData[userId]) {
                for (const plant of userPlantsData[userId]) {
                    const plantRef = userRef.collection('user_plants').doc(plant.plantId);

                    // Trích xuất subcollections trước khi lưu doc cha của cây
                    const { care_history, schedules, ...plantMeta } = plant;
                    await plantRef.set(plantMeta);

                    // Ghi subcollection: care_history
                    for (const log of care_history) {
                        await plantRef.collection('care_history').doc(log.logId).set(log);
                    }
                    // Ghi subcollection: schedules
                    for (const sch of schedules) {
                        await plantRef.collection('schedules').doc(sch.scheduleId).set(sch);
                    }
                    console.log(`    ├── Đã tạo cây: ${plantMeta.customName} kèm Lịch trình & Nhật ký thành công.`);
                }
            }
        }

        // 2. Sinh dữ liệu plant_templates
        for (const template of plantTemplatesData) {
            await db.collection('plant_templates').doc(template.templateId).set(template);
            console.log(`✔️  Đã nạp mẫu cây thư viện: ${template.name}`);
        }

        // 3. Sinh dữ liệu articles
        for (const article of articlesData) {
            await db.collection('articles').doc(article.articleId).set(article);
            console.log(`✔️  Đã nạp bài viết cẩm nang: ${article.title}`);
        }

        // 4. Sinh dữ liệu community_posts và Subcollection: comments
        for (const post of communityPostsData) {
            const postRef = db.collection('community_posts').doc(post.postId);
            const { comments, ...postMeta } = post;
            await postRef.set(postMeta);

            for (const cmt of comments) {
                await postRef.collection('comments').doc(cmt.commentId).set(cmt);
            }
            console.log(`✔️  Đã nạp bài đăng cộng đồng của [${postMeta.authorName}] kèm bình luận.`);
        }

        // 5. Sinh dữ liệu ai_diagnoses
        for (const diag of aiDiagnosesData) {
            await db.collection('ai_diagnoses').doc(diag.diagnosisId).set(diag);
            console.log(`✔️  Đã nạp lịch sử chẩn đoán AI ID: ${diag.diagnosisId}`);
        }

        // 6. Sinh dữ liệu qa_threads và Subcollection: replies
        for (const thread of qaThreadsData) {
            const threadRef = db.collection('qa_threads').doc(thread.threadId);
            const { replies, ...threadMeta } = thread;
            await threadRef.set(threadMeta);

            for (const rep of replies) {
                await threadRef.collection('replies').doc(rep.replyId).set(rep);
            }
            console.log(`✔️  Đã dựng phòng chat hỗ trợ 1-1 ID: ${threadMeta.threadId}`);
        }

        console.log('\n🎉 Chúc mừng! Toàn bộ cấu trúc thực thể đã được thiết lập thành công trên Cloud Firestore của bạn.');
        process.exit(0);

    } catch (error) {
        console.error('❌ Đã xảy ra lỗi trong quá trình nạp DB:', error);
        process.exit(1);
    }
}

// Chạy Script
runSeeder();