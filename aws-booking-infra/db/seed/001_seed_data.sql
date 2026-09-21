INSERT INTO hotel_bookings (
    id,
    org_id,
    hotel_id,
    city,
    checkin_date,
    checkout_date,
    amount,
    status,
    created_at
)
SELECT
    gen_random_uuid(),
    (
        ARRAY[
            '11111111-1111-1111-1111-111111111111'::uuid,
            '22222222-2222-2222-2222-222222222222'::uuid,
            '33333333-3333-3333-3333-333333333333'::uuid,
            '44444444-4444-4444-4444-444444444444'::uuid
        ]
    )[1 + (gs % 4)],
    'hotel-' || (1 + (gs % 20)),
    (
        ARRAY[
            'delhi',
            'mumbai',
            'bangalore',
            'hyderabad',
            'chennai',
            'pune'
        ]
    )[1 + (gs % 6)],
    CURRENT_DATE + (gs % 30),
    CURRENT_DATE + (gs % 30) + 2,
    ROUND((100 + random() * 900)::numeric, 2),
    (
        ARRAY[
            'confirmed',
            'pending',
            'cancelled',
            'completed'
        ]
    )[1 + (gs % 4)],
    NOW() - ((gs % 45) || ' days')::interval
FROM generate_series(1, 150) AS gs;

INSERT INTO booking_events (
    booking_id,
    event_type,
    payload,
    created_at
)
SELECT
    id,
    CASE
        WHEN row_number() OVER () % 3 = 0 THEN 'booking.created'
        WHEN row_number() OVER () % 3 = 1 THEN 'booking.confirmed'
        ELSE 'booking.updated'
    END,
    jsonb_build_object(
        'source', 'seed',
        'booking_id', id
    ),
    created_at + interval '1 hour'
FROM (
    SELECT id, created_at
    FROM hotel_bookings
    ORDER BY created_at
    LIMIT 75
) b;
