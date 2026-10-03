package com.fitlyfe.fitlyfe_backend.api.workout.repository

import com.fitlyfe.fitlyfe_backend.api.workout.entity.ExerciseSetEntity
import com.fitlyfe.fitlyfe_backend.api.workout.entity.WorkoutExerciseEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Modifying
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import java.util.UUID

interface ExerciseSetRepository : JpaRepository<ExerciseSetEntity, UUID> {
    fun findByWorkoutExerciseOrderBySetNumberAsc(workoutExercise: WorkoutExerciseEntity): List<ExerciseSetEntity>
    fun findByWorkoutExerciseIdInOrderBySetNumberAsc(workoutExerciseIds: Collection<UUID>): List<ExerciseSetEntity>

    @Modifying
    @Query("delete from ExerciseSetEntity s where s.workoutExercise in :exercises")
    fun deleteByWorkoutExerciseIn(@Param("exercises") exercises: Collection<WorkoutExerciseEntity>)
}
