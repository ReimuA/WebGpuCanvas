export interface Clock {
    startDate: number
    reset(): void
    timeElapsed(): number
}

export function createClock(): Clock {
    const startDate = Date.now()

    return {
        startDate,
        reset() {
            this.startDate = Date.now()
        },
        timeElapsed() {
            return Date.now() - this.startDate;
        },
    }
}