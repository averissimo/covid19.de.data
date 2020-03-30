test_that("identify.ranges works", {
  expect_equal(identify.ranges(c(1:3, 5, 7:8, 10:12, 14:15)),
               c("(ObjectId >= 1 AND ObjectId <= 3)",
                 "ObjectId = 5",
                 "(ObjectId >= 7 AND ObjectId <= 8)",
                 "(ObjectId >= 10 AND ObjectId <= 12)",
                 "(ObjectId >= 14 AND ObjectId <= 15)"))
  expect_equal(identify.ranges(c(1:3, 5, 7:8, 10:12, 14)),
               c("(ObjectId >= 1 AND ObjectId <= 3)",
                 "ObjectId = 5",
                 "(ObjectId >= 7 AND ObjectId <= 8)",
                 "(ObjectId >= 10 AND ObjectId <= 12)",
                 "ObjectId = 14"))
  expect_equal(identify.ranges(c(1, 5, 7:8, 10:12, 14)),
               c("ObjectId = 1",
                 "ObjectId = 5",
                 "(ObjectId >= 7 AND ObjectId <= 8)",
                 "(ObjectId >= 10 AND ObjectId <= 12)",
                 "ObjectId = 14"))
  expect_equal(identify.ranges(c(1, 5, 7:8, 10:12, 14:19)),
               c("ObjectId = 1",
                 "ObjectId = 5",
                 "(ObjectId >= 7 AND ObjectId <= 8)",
                 "(ObjectId >= 10 AND ObjectId <= 12)",
                 "(ObjectId >= 14 AND ObjectId <= 19)"))
})

