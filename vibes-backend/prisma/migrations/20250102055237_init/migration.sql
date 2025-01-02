-- CreateTable
CREATE TABLE "Emotion" (
    "id" SERIAL NOT NULL,
    "type" TEXT NOT NULL,
    "intensity" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Emotion_pkey" PRIMARY KEY ("id")
);
